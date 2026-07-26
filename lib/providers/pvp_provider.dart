import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth/token_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/pvp_realtime_service.dart';
import '../data/datasources/remote/pvp_sprint_datasource.dart';
import '../data/datasources/remote/pet_screen_datasource.dart';
import '../data/datasources/remote/activity_stats_datasource.dart';
import '../data/datasources/remote/friends_datasource.dart';
import '../data/models/pvp_models.dart';
import '../data/models/friends_response.dart';

enum PvpMatchmakingState { idle, connecting, waiting, countdown, running }

class PvpProvider extends ChangeNotifier {
  final PvpSprintDatasource _pvpDatasource;
  final PetScreenDatasource _petDatasource;
  final ActivityStatsDatasource _activityDatasource;
  final FriendsDatasource _friendsDatasource;
  late final PvpRealtimeService _realtimeService;

  PvpMatchmakingState _matchmakingState = PvpMatchmakingState.idle;
  PvpMatchResponse? _currentMatch;
  Duration? _serverTimeOffset;

  PvpMatchmakingState get matchmakingState => _matchmakingState;
  PvpMatchResponse? get currentMatch => _currentMatch;
  int get countdownSecondsRemaining {
    if (_currentMatch?.countdownEndsAt == null || _serverTimeOffset == null) {
      return 0;
    }
    final estimatedServerNow = DateTime.now().toUtc().add(_serverTimeOffset!);
    final remaining = _currentMatch!.countdownEndsAt!.difference(
      estimatedServerNow,
    );
    return remaining.isNegative ? 0 : remaining.inSeconds + 1;
  }

  String get currentOpponentName {
    final opponents =
        _currentMatch?.participants
            .where((p) => p.participantTypeCode != 'user' || p.userId == null)
            .toList() ??
        [];
    if (opponents.isNotEmpty) {
      return opponents.first.displayName ?? 'Đối thủ';
    }
    if (_currentMatch?.participants.isNotEmpty == true) {
      return _currentMatch!.participants.first.displayName ?? 'Đối thủ';
    }
    return 'Đối thủ';
  }

  PvpProvider({ApiClient? apiClient})
    : _pvpDatasource = PvpSprintDatasource(apiClient),
      _petDatasource = PetScreenDatasource(apiClient),
      _activityDatasource = ActivityStatsDatasource(apiClient: apiClient),
      _friendsDatasource = FriendsDatasource(apiClient ?? ApiClient()) {
    _realtimeService = PvpRealtimeService(
      ApiConstants.baseUrl,
      _readAccessToken,
    );
    _registerRealtimeHandlers();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _petName = '...';
  String get petName => _petName;

  final String _spiritAffinity = 'Thực Vật';
  String get spiritAffinity => _spiritAffinity;

  int _currentEnergy = 0;
  int get currentEnergy => _currentEnergy;

  int _maxEnergy = 100;
  int get maxEnergy => _maxEnergy;

  int _currentBond = 0;
  int get currentBond => _currentBond;

  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  List<PvpInviteResponse> _incomingInvites = [];
  List<PvpInviteResponse> get incomingInvites => _incomingInvites;

  List<PvpMatchResponse> _matchHistory = [];
  List<PvpMatchResponse> get matchHistory => _matchHistory;

  List<FriendsResponse> _friendsList = [];
  List<FriendsResponse> get friendsList => _friendsList;

  Future<void> fetchWaitingRoomData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _petDatasource.getPetName(),
        _petDatasource.getPetStatus(),
        _activityDatasource.getStatistic(ActivityStatsRange.daily),
        _friendsDatasource.getFriends(),
        _pvpDatasource.getIncomingInvites(),
        _pvpDatasource.getMatchHistory(),
      ]);

      final petNameResp = futures[0] as dynamic;
      final petStatusResp = futures[1] as dynamic;
      final activityResp = futures[2] as dynamic;
      final friendsResp = futures[3] as List<FriendsResponse>;
      final invitesResp = futures[4] as dynamic;
      final historyResp = futures[5] as dynamic;

      if (petNameResp.success && petNameResp.data != null) {
        _petName = petNameResp.data!.petName;
      }

      if (petStatusResp.success && petStatusResp.data != null) {
        _currentEnergy = petStatusResp.data!.currentEnergy;
        _maxEnergy = petStatusResp.data!.maxEnergy;
        _currentBond = petStatusResp.data!.currentBond;
      }

      if (activityResp.success && activityResp.data != null) {
        int total = 0;
        for (var item in activityResp.data!.data) {
          total += (item.stepCount as int);
        }
        _todaySteps = total;
      }

      _friendsList = friendsResp;

      if (invitesResp.success && invitesResp.data != null) {
        _incomingInvites = invitesResp.data!;
      }

      if (historyResp.success && historyResp.data != null) {
        _matchHistory = historyResp.data!;
      }
    } catch (e) {
      debugPrint('Error fetching PvP waiting room data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _readAccessToken() async {
    final token = TokenStorage.token;
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  void _registerRealtimeHandlers() {
    _realtimeService.on('match.assigned', (payload) {
      final matchId = payload['matchId'] as String? ?? '';
      if (matchId.isEmpty) return;
      _processMatchAssigned(matchId);
    });
  }

  Future<bool> _ensureRealtimeConnected() async {
    if (_realtimeService.isConnected) {
      return true;
    }
    try {
      await _realtimeService.connect();
      return true;
    } catch (e) {
      debugPrint('Realtime connect failed: $e');
      return false;
    }
  }

  void _updateState(PvpMatchmakingState state) {
    _matchmakingState = state;
    notifyListeners();
  }

  void _updateServerOffset(DateTime? serverTime) {
    if (serverTime == null) return;
    _serverTimeOffset = serverTime.difference(DateTime.now().toUtc());
  }

  Future<void> _processMatchAssigned(String matchId) async {
    if (matchId.isEmpty) return;
    await _joinAndSyncMatch(matchId);
  }

  Future<void> _joinAndSyncMatch(String matchId) async {
    try {
      await _realtimeService.joinMatch(matchId);
    } catch (e) {
      debugPrint('JoinMatch failed: $e');
    }

    final matchResponse = await _pvpDatasource.getMatch(matchId);
    if (!matchResponse.success || matchResponse.data == null) {
      debugPrint('GET match failed after assigned: ${matchResponse.message}');
      return;
    }

    final match = matchResponse.data!;
    _currentMatch = match;
    _updateServerOffset(match.serverTime);

    if (match.statusCode == 'countdown') {
      _updateState(PvpMatchmakingState.countdown);
      return;
    }

    if (match.statusCode == 'running') {
      _updateState(PvpMatchmakingState.running);
      return;
    }

    _updateState(PvpMatchmakingState.waiting);
  }

  Future<void> startMatchmaking() async {
    if (_matchmakingState != PvpMatchmakingState.idle) {
      return;
    }

    _updateState(PvpMatchmakingState.connecting);
    final connected = await _ensureRealtimeConnected();
    if (!connected) {
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final response = await _pvpDatasource.startMatchmaking();
    if (!response.success || response.data == null) {
      debugPrint('Matchmaking failed: ${response.message}');
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final match = response.data!;
    _currentMatch = match;
    _updateServerOffset(match.serverTime);

    if (match.statusCode == 'waiting' ||
        match.matchId == '00000000-0000-0000-0000-000000000000') {
      _updateState(PvpMatchmakingState.waiting);
      return;
    }

    if (match.matchId.isNotEmpty) {
      await _joinAndSyncMatch(match.matchId);
      return;
    }

    _updateState(PvpMatchmakingState.waiting);
  }

  Future<void> cancelMatchmaking() async {
    if (_matchmakingState != PvpMatchmakingState.waiting) {
      return;
    }

    final response = await _pvpDatasource.cancelMatchmaking();
    if (response.success) {
      _currentMatch = null;
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    if (response.status == 404) {
      // Match was already assigned or queue expired.
      // Keep waiting state until match.assigned arrives or caller resets state.
      return;
    }

    _currentMatch = null;
    _updateState(PvpMatchmakingState.idle);
  }

  Future<bool> acceptChallenge(String inviteId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _pvpDatasource.respondToInvite(
        inviteId: inviteId,
        accepted: true,
      );

      if (response.success) {
        _incomingInvites.removeWhere((invite) => invite.inviteId == inviteId);
        notifyListeners();
        return true;
      }

      debugPrint('Accept challenge failed: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('Accept challenge exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectChallenge(String inviteId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _pvpDatasource.respondToInvite(
        inviteId: inviteId,
        accepted: false,
      );

      if (response.success) {
        _incomingInvites.removeWhere((invite) => invite.inviteId == inviteId);
        notifyListeners();
        return true;
      }

      debugPrint('Reject challenge failed: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('Reject challenge exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
