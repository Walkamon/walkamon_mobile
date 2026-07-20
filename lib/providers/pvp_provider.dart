import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../data/datasources/remote/pvp_sprint_datasource.dart';
import '../data/datasources/remote/pet_screen_datasource.dart';
import '../data/datasources/remote/activity_stats_datasource.dart';
import '../data/datasources/remote/friends_datasource.dart';
import '../data/models/pvp_models.dart';
import '../data/models/friends_response.dart';

class PvpProvider extends ChangeNotifier {
  final PvpSprintDatasource _pvpDatasource;
  final PetScreenDatasource _petDatasource;
  final ActivityStatsDatasource _activityDatasource;
  final FriendsDatasource _friendsDatasource;

  PvpProvider({ApiClient? apiClient})
      : _pvpDatasource = PvpSprintDatasource(apiClient),
        _petDatasource = PetScreenDatasource(apiClient),
        _activityDatasource = ActivityStatsDatasource(apiClient: apiClient),
        _friendsDatasource = FriendsDatasource(apiClient ?? ApiClient());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _petName = '...';
  String get petName => _petName;

  String _spiritAffinity = 'Thực Vật';
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

  void acceptChallenge(String inviteId) {
    // API Call
  }
  
  void rejectChallenge(String inviteId) {
    // API Call
  }
}