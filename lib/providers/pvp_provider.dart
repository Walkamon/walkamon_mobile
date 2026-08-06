import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/datasources/remote/pvp_sprint_datasource.dart';
import '../data/datasources/remote/pet_screen_datasource.dart';
import '../data/datasources/remote/activity_stats_datasource.dart';
import '../data/datasources/remote/friends_datasource.dart';
import '../data/models/pvp_models.dart';
import '../data/models/friends_response.dart';
import 'presence_provider.dart';

abstract class PvpSignalRService {
  bool get isConnected;
  bool get isMatchRoomJoined;
  String? get hubUrl;
  String? get connectionId;

  Future<void> connect();
  Future<void> disconnect();
  Future<bool> joinMatch(String matchId);
  Future<void> leaveMatch(String matchId);
  Future<Map<String, dynamic>> readyMatch(String matchId);
  void setEventHandlers({
    required void Function(Map<String, dynamic> event) onAssigned,
    required void Function(Map<String, dynamic> event) onProgress,
    required void Function(Map<String, dynamic> event) onFinished,
    required void Function(Map<String, dynamic> event) onSettling,
    required void Function(Map<String, dynamic> event) onCancelled,
    required void Function(Map<String, dynamic> event) onCountdownStarted,
    required void Function(Map<String, dynamic> event) onStarted,
    void Function(Map<String, dynamic> event)? onForfeited,
    void Function(Map<String, dynamic> event)? onPresenceChanged,
    void Function(Map<String, dynamic> event)? onQueueFailed,
  });

  void setReconnectedHandler(Future<void> Function()? onReconnected);

  Future<void> emitEvent(Map<String, dynamic> event);
}

class DefaultPvpSignalRService implements PvpSignalRService {
  final String apiBaseUrl;
  final Future<String> Function()? accessTokenFactory;
  final String? configuredHubUrl;
  final List<String>? serverMethodNames;
  final String joinMethodName;
  final String leaveMethodName;

  DefaultPvpSignalRService({
    required this.apiBaseUrl,
    this.accessTokenFactory,
    this.configuredHubUrl,
    this.serverMethodNames,
    this.joinMethodName = 'JoinMatch',
    this.leaveMethodName = 'LeaveMatch',
  });

  late HubConnection _connection;
  bool _isConnected = false;
  bool _isMatchRoomJoined = false;

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isMatchRoomJoined => _isMatchRoomJoined;

  void Function(Map<String, dynamic> event)? _onAssigned;
  void Function(Map<String, dynamic> event)? _onProgress;
  void Function(Map<String, dynamic> event)? _onFinished;
  void Function(Map<String, dynamic> event)? _onSettling;
  void Function(Map<String, dynamic> event)? _onCancelled;
  void Function(Map<String, dynamic> event)? _onCountdownStarted;
  void Function(Map<String, dynamic> event)? _onStarted;
  void Function(Map<String, dynamic> event)? _onForfeited;
  void Function(Map<String, dynamic> event)? _onPresenceChanged;
  void Function(Map<String, dynamic> event)? _onQueueFailed;
  Future<void> Function()? _onReconnected;

  String _hubPath() => (configuredHubUrl?.isNotEmpty == true
      ? configuredHubUrl!
      : '${apiBaseUrl.replaceAll(RegExp(r'/*$'), '')}/hubs/pvp-sprint');

  @override
  String? get hubUrl => configuredHubUrl ?? _hubPath();

  @override
  String? get connectionId {
    try {
      return (_connection as dynamic).connectionId as String?;
    } catch (_) {
      return null;
    }
  }

  /// Debug helper: log access token metadata and negotiate URL info.
  Future<void> debugLogAccessTokenAndNegotiateInfo() async {
    try {
      if (accessTokenFactory == null) {
        _log('accessTokenFactory is null = true');
      } else {
        _log('accessTokenFactory is null = false');
        try {
          final t = await accessTokenFactory!();
          _log('Token: length=${t.length}');
          final prefix = t.length > 10 ? t.substring(0, 10) : t;
          _log('Token prefix=$prefix');

          // Compare with in-memory and SharedPreferences storage used by REST
          try {
            final ram = TokenStorage.token;
            _log(
              'TokenStorage.token ${ram == null ? 'null' : 'present (length=${ram.length})'}',
            );
          } catch (_) {}

          try {
            final prefs = await SharedPreferences.getInstance();
            final stored = prefs.getString('access_token');
            if (stored == null) {
              _log('SharedPreferences(access_token) = null');
            } else {
              _log('SharedPreferences(access_token): length=${stored.length}');
              final eq = stored == t ? 'MATCH' : 'DIFFER';
              _log('SharedPreferences token vs accessTokenFactory: $eq');
            }
          } catch (e) {
            _log('Failed to read SharedPreferences: $e');
          }
        } catch (e) {
          _log('accessTokenFactory threw: $e');
        }
      }

      // Negotiate URL
      final negotiate =
          '${_hubPath().replaceAll(RegExp(r'/*$'), '')}/negotiate';
      _log('Negotiate URL: $negotiate');
      _log(
        'SignalR negotiation transport: access_token will be sent as query param when accessTokenFactory is used',
      );
    } catch (e) {
      _log('debugLogAccessTokenAndNegotiateInfo failed: $e');
    }
  }

  @override
  Future<void> connect() async {
    if (_isConnected) return;

    _log('SignalR Connecting');

    final tokenFactory = accessTokenFactory != null
        ? () async {
            final t = await accessTokenFactory!();
            return t; // do NOT add 'Bearer '
          }
        : null;

    final options = HttpConnectionOptions();
    if (tokenFactory != null) {
      (options as dynamic).accessTokenFactory = tokenFactory;
    }

    _connection = HubConnectionBuilder()
        .withUrl(_hubPath(), options: options)
        .withAutomaticReconnect()
        .build();

    final methodNames =
        serverMethodNames ??
        [
          'match.assigned',
          'MatchAssigned',
          'EventBroadcast',
          'match.progress',
          'MatchProgress',
          'match.countdown.started',
          'match.started',
          'match.finished',
          'match.settling',
          'match.cancelled',
          'presence.changed',
          'queue.failed',
        ];
    for (final name in methodNames) {
      _log('Registering SignalR handler: $name');
      _connection.on(name, (args) => _onMethodReceived(name, args));
    }

    _connection.onclose(({error}) {
      _isConnected = false;
      _isMatchRoomJoined = false;
      _log('SignalR Disconnected: ${error ?? 'no error'}');
      _log('Disconnected');
    });

    _connection.onreconnecting(({error}) {
      _log('SignalR Reconnecting: ${error ?? 'no error'}');
      _log('Reconnecting');
    });

    _connection.onreconnected(({connectionId}) async {
      _log('SignalR Reconnected connectionId=$connectionId');
      _log('Reconnected');
      _isConnected = true;
      if (_onReconnected != null) {
        await _onReconnected!();
      }
    });

    try {
      _log('Before connection.start()');
      await _connection.start();
      _log('After connection.start()');
      // Try to read state and connection id for debugging
      try {
        final state = (_connection as dynamic).state;
        _log('Connection state after start: $state');
      } catch (_) {}
      try {
        final connId = connectionId;
        _log('ConnectionId after start: ${connId ?? 'unknown'}');
      } catch (_) {}
      _isConnected = true;
      _log('SignalR Connected');
      _log('Connected');
    } catch (e, st) {
      _isConnected = false;
      _log('SignalR START FAILED');
      _log(e.toString());
      debugPrint(st.toString());
      rethrow;
    }
  }

  void _onMethodReceived(String methodName, List<Object?>? args) {
    _log('SignalR method received: $methodName');
    if (args == null || args.isEmpty) return;

    final payload = args.first;
    Map<String, dynamic> data;
    if (payload is String) {
      try {
        data = json.decode(payload) as Map<String, dynamic>;
      } catch (e) {
        return;
      }
    } else if (payload is Map<String, dynamic>) {
      data = payload;
    } else if (payload is Map) {
      data = Map<String, dynamic>.from(payload);
    } else {
      return;
    }

    data['_receivedMethod'] = methodName;
    final eventType = data['eventType']?.toString() ?? '';
    switch (eventType) {
      case 'match.assigned':
        _onAssigned?.call(data);
        break;
      case 'match.progress':
        _onProgress?.call(data);
        break;
      case 'match.countdown.started':
        _onCountdownStarted?.call(data);
        break;
      case 'match.started':
        _onStarted?.call(data);
        break;
      case 'match.forfeited':
        _onForfeited?.call(data);
        break;
      case 'match.finished':
        _onFinished?.call(data);
        break;
      case 'match.settling':
        _onSettling?.call(data);
        break;
      case 'match.cancelled':
        _onCancelled?.call(data);
        break;
      case 'presence.changed':
        _onPresenceChanged?.call(data);
        break;
      case 'queue.failed':
        _onQueueFailed?.call(data);
        break;
      default:
        // Fallback: nếu method name là 'presence.changed' nhưng eventType khác
        if (methodName == 'presence.changed') {
          _onPresenceChanged?.call(data);
        }
        break;
    }
  }

  @override
  void setReconnectedHandler(Future<void> Function()? onReconnected) {
    _onReconnected = onReconnected;
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _connection.stop();
    _isConnected = false;
    _isMatchRoomJoined = false;
    _log('SignalR Disconnected');
  }

  @override
  Future<bool> joinMatch(String matchId) async {
    if (!_isConnected) {
      _log('JoinMatch failed: SignalR not connected', matchId: matchId);
      return false;
    }

    try {
      await _connection.invoke('JoinMatch', args: <Object>[matchId]);
      _isMatchRoomJoined = true;
      _log('JoinMatch Success', matchId: matchId);
      return true;
    } catch (error) {
      _log('JoinMatch Failure: $error', matchId: matchId);
      return false;
    }
  }

  @override
  Future<void> leaveMatch(String matchId) async {
    if (!_isConnected) return;
    try {
      await _connection.invoke('LeaveMatch', args: <Object>[matchId]);
    } catch (e) {
      // ignore invocation errors but log
      _log('LeaveMatch invocation failed: $e', matchId: matchId);
    }
    _isMatchRoomJoined = false;
    _log('LeaveMatch', matchId: matchId);
  }

  @override
  Future<Map<String, dynamic>> readyMatch(String matchId) async {
    if (!_isConnected) {
      return <String, dynamic>{'matchId': matchId, 'allReady': false};
    }
    try {
      final result = await _connection.invoke(
        'ReadyMatch',
        args: <Object>[matchId],
      );
      if (result is Map<String, dynamic>) {
        return result;
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return <String, dynamic>{'matchId': matchId, 'allReady': false};
    } catch (_) {
      return <String, dynamic>{'matchId': matchId, 'allReady': false};
    }
  }

  @override
  void setEventHandlers({
    required void Function(Map<String, dynamic> event) onAssigned,
    required void Function(Map<String, dynamic> event) onProgress,
    required void Function(Map<String, dynamic> event) onFinished,
    required void Function(Map<String, dynamic> event) onSettling,
    required void Function(Map<String, dynamic> event) onCancelled,
    void Function(Map<String, dynamic> event)? onCountdownStarted,
    void Function(Map<String, dynamic> event)? onStarted,
    void Function(Map<String, dynamic> event)? onForfeited,
    void Function(Map<String, dynamic> event)? onPresenceChanged,
    void Function(Map<String, dynamic> event)? onQueueFailed,
  }) {
    _onAssigned = onAssigned;
    _onProgress = onProgress;
    _onFinished = onFinished;
    _onSettling = onSettling;
    _onCancelled = onCancelled;
    _onCountdownStarted = onCountdownStarted;
    _onStarted = onStarted;
    _onForfeited = onForfeited;
    _onPresenceChanged = onPresenceChanged;
    _onQueueFailed = onQueueFailed;
  }

  @override
  Future<void> emitEvent(Map<String, dynamic> event) async {
    // For compatibility: allow manual injection
    final eventType = event['eventType']?.toString() ?? 'unknown';
    switch (eventType) {
      case 'match.assigned':
        _onAssigned?.call(event);
        break;
      case 'match.progress':
        _onProgress?.call(event);
        break;
      case 'match.countdown.started':
        _onCountdownStarted?.call(event);
        break;
      case 'match.started':
        _onStarted?.call(event);
        break;
      case 'match.finished':
        _onFinished?.call(event);
        break;
      case 'match.settling':
        _onSettling?.call(event);
        break;
      case 'match.cancelled':
        _onCancelled?.call(event);
        break;
      case 'presence.changed':
        _onPresenceChanged?.call(event);
        break;
      case 'queue.failed':
        _onQueueFailed?.call(event);
        break;
      default:
        break;
    }
  }

  void _log(String message, {String? matchId}) {
    debugPrint(
      '[PvP][${DateTime.now().toIso8601String()}] $message${matchId != null ? ' matchId=$matchId' : ''}',
    );
  }
}

enum PvpMatchmakingState {
  idle,
  connecting,
  waiting,
  countdown,
  running,
  invitePending,
  finished,
  cancelled,
}

enum PvpCountdownPhase { beforeStart, countdown, finished }

PvpCountdownPhase resolveCountdownPhase({
  required bool countdownActive,
  required DateTime? countdownStartsAt,
  required DateTime? countdownEndsAt,
  required DateTime serverNow,
}) {
  if (!countdownActive ||
      countdownStartsAt == null ||
      countdownEndsAt == null) {
    return PvpCountdownPhase.finished;
  }

  if (serverNow.isBefore(countdownStartsAt)) {
    return PvpCountdownPhase.beforeStart;
  }

  final remainingMilliseconds = countdownEndsAt
      .difference(serverNow)
      .inMilliseconds;
  if (serverNow.isAtSameMomentAs(countdownEndsAt) ||
      serverNow.isAfter(countdownEndsAt) ||
      remainingMilliseconds <= 0) {
    return PvpCountdownPhase.finished;
  }

  return PvpCountdownPhase.countdown;
}

class PvpProvider extends ChangeNotifier {
  final PvpSprintDatasource _pvpDatasource;
  final PetScreenDatasource _petDatasource;
  final ActivityStatsDatasource _activityDatasource;
  final FriendsDatasource _friendsDatasource;
  final PvpSignalRService _signalRService;
  final PresenceProvider? _presenceProvider;
  StreamSubscription<Map<String, dynamic>>? _presenceEventSubscription;
  Future<void>? _signalRInitialization;

  PvpProvider({
    ApiClient? apiClient,
    PvpSprintDatasource? pvpDatasource,
    PetScreenDatasource? petDatasource,
    ActivityStatsDatasource? activityDatasource,
    FriendsDatasource? friendsDatasource,
    PvpSignalRService? signalRService,
    String? signalRHubUrl,
    List<String>? signalRMethodNames,
    String? signalRJoinMethod,
    String? signalRLeaveMethod,
    PresenceProvider? presenceProvider,
    Duration matchmakingRecoveryDelay = const Duration(seconds: 15),
    Duration matchmakingRecoveryInterval = const Duration(seconds: 2),
  }) : _pvpDatasource = pvpDatasource ?? PvpSprintDatasource(apiClient),
       _petDatasource = petDatasource ?? PetScreenDatasource(apiClient),
       _activityDatasource =
           activityDatasource ?? ActivityStatsDatasource(apiClient: apiClient),
       _friendsDatasource =
           friendsDatasource ?? FriendsDatasource(apiClient ?? ApiClient()),
       _presenceProvider = presenceProvider,
       _matchmakingRecoveryDelay = matchmakingRecoveryDelay,
       _matchmakingRecoveryInterval = matchmakingRecoveryInterval,
       _signalRService =
           signalRService ??
           DefaultPvpSignalRService(
             apiBaseUrl: ApiConstants.baseUrl,
             accessTokenFactory: () async {
               // Reuse the same token sources as REST: in-memory TokenStorage, then SharedPreferences
               final ram = TokenStorage.token;
               if (ram != null && ram.isNotEmpty) return ram;
               final prefs = await SharedPreferences.getInstance();
               final stored = prefs.getString('access_token');
               if (stored != null && stored.isNotEmpty) return stored;
               throw Exception(
                 'No access token available for SignalR accessTokenFactory',
               );
             },
             configuredHubUrl: signalRHubUrl,
             serverMethodNames: signalRMethodNames,
             joinMethodName: signalRJoinMethod ?? 'JoinMatch',
             leaveMethodName: signalRLeaveMethod ?? 'LeaveMatch',
           ) {
    _presenceEventSubscription = _presenceProvider?.events.listen(
      (event) => unawaited(_handlePresenceHubEvent(event)),
    );
    final pendingAssigned = _presenceProvider?.latestMatchAssignedEvent;
    if (pendingAssigned != null) {
      scheduleMicrotask(
        () => unawaited(_handlePresenceHubEvent(pendingAssigned)),
      );
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasReceivedAssignedEvent = false;
  bool _hasMatchRoomJoined = false;
  String? _activeMatchId;
  DateTime? _matchmakingStartedAt;
  bool _inviteDeclined = false;
  bool get inviteDeclined => _inviteDeclined;

  void clearInviteDeclined() {
    _inviteDeclined = false;
    notifyListeners();
  }

  final Set<String> _processedEventIds = <String>{};
  final Map<String, int> _lastSequences = <String, int>{};

  String _petName = '...';
  String get petName => _petName;

  String _spiritAffinityCode = 'sprout';
  String get spiritAffinityCode => _spiritAffinityCode;
  String get spiritAffinity => _spiritAffinityLabel;
  String _spiritAffinityLabel = '';

  int _petStageNo = 0;
  int get petStageNo => _petStageNo;

  String get mySpiritAffinityCode =>
      _myParticipant?.spiritAffinityCode?.trim().isNotEmpty == true
      ? _myParticipant!.spiritAffinityCode!.trim()
      : _spiritAffinityCode;

  String get opponentSpiritAffinityCode {
    final participants = _currentMatch?.participants;
    if (participants == null) return 'sprout';
    for (final p in participants) {
      if (!_isMyParticipant(p) &&
          p.spiritAffinityCode != null &&
          p.spiritAffinityCode!.trim().isNotEmpty) {
        return p.spiritAffinityCode!.trim();
      }
    }
    return 'sprout';
  }

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
  int _incomingInvitesTotal = 0;
  int get incomingInvitesTotal => _incomingInvitesTotal;

  List<PvpInviteResponse> _sentInvites = [];
  List<PvpInviteResponse> get sentInvites => _sentInvites;
  int _sentInvitesTotal = 0;
  int get sentInvitesTotal => _sentInvitesTotal;

  List<PvpMatchResponse> _matchHistory = [];
  List<PvpMatchResponse> get matchHistory => _matchHistory;

  int _historyPage = 1;
  int _historyTotal = 0;
  bool _historyLoading = false;
  bool _historyLoadingMore = false;
  String _historyMatchType = '';
  String _historyResult = '';
  bool _historyIncludeActive = false;

  int get historyPage => _historyPage;
  int get historyTotal => _historyTotal;
  int get historyPageSize => 20;
  int get historyTotalPages =>
      _historyTotal == 0 ? 1 : (_historyTotal / historyPageSize).ceil();
  bool get historyLoading => _historyLoading;
  bool get historyLoadingMore => _historyLoadingMore;
  bool get historyHasMore => _matchHistory.length < _historyTotal;
  String get historyMatchType => _historyMatchType;
  String get historyResultFilter => _historyResult;

  /// UC-70 — load / refresh / paginate match history.
  Future<void> loadMatchHistory({
    bool refresh = false,
    int? page,
    String? matchType,
    String? result,
    DateTime? from,
    DateTime? to,
    bool? includeActive,
  }) async {
    if (_historyLoading) return;
    _historyLoading = true;
    if (matchType != null) _historyMatchType = matchType;
    if (result != null) _historyResult = result;
    if (includeActive != null) _historyIncludeActive = includeActive;

    int targetPage = page ?? (refresh ? 1 : _historyPage);
    if (targetPage < 1) targetPage = 1;
    notifyListeners();

    try {
      final response = await _pvpDatasource.getMatchHistory(
        page: targetPage,
        pageSize: historyPageSize,
        matchType: _historyMatchType,
        result: _historyResult,
        from: from,
        to: to,
        includeActive: _historyIncludeActive,
      );

      if (response.success && response.data != null) {
        final pageData = response.data!;
        _historyPage = pageData.page;
        _historyTotal = pageData.total;
        _matchHistory = List<PvpMatchResponse>.from(pageData.items);
      } else {
        _matchHistory = [];
        _historyTotal = 0;
        debugPrint(
          '[PvP] loadMatchHistory failed status=${response.status} '
          'message=${response.message}',
        );
      }
    } catch (e, st) {
      debugPrint('[PvP] loadMatchHistory error: $e\n$st');
      _matchHistory = [];
      _historyTotal = 0;
    } finally {
      _historyLoading = false;
      _historyLoadingMore = false;
      notifyListeners();
    }
  }

  List<FriendsResponse> _friendsList = [];
  List<FriendsResponse> get friendsList => _friendsList;

  PvpMatchmakingState _matchmakingState = PvpMatchmakingState.idle;
  PvpMatchmakingState get matchmakingState => _matchmakingState;

  PvpMatchResponse? _currentMatch;
  PvpMatchResponse? get currentMatch => _currentMatch;

  Timer? _countdownTicker;
  Timer? _raceTicker;
  Timer? _settlementPollTimer;
  final Duration _matchmakingRecoveryDelay;
  final Duration _matchmakingRecoveryInterval;
  Timer? _matchmakingRecoveryTimer;
  int _matchmakingSessionGeneration = 0;
  bool _matchmakingRecoveryInFlight = false;
  Duration? _serverOffset;
  DateTime? _countdownStartsAt;
  DateTime? _countdownEndsAt;
  bool _countdownActive = false;
  int? _lastLoggedCountdownValue;

  DateTime? _raceStartedAt;
  Duration _raceDuration = const Duration(seconds: 30);
  double _raceTimeProgress = 0.0;
  double _myProgress = 0.0;
  double _opponentProgress = 0.0;
  bool _isRaceFinished = false;

  // Matchmaking trace
  String _lastMatchmakingStep = 'none';
  void _traceMatchmaking(String step) {
    _lastMatchmakingStep = step;
    _log(step);
  }

  PvpMatchResultResponse? _matchResult;
  PvpMatchResultResponse? get matchResult => _matchResult;

  PvpRewardClaimResponse? _lastClaimResponse;
  PvpRewardClaimResponse? get lastClaimResponse => _lastClaimResponse;

  /// Used when server result is not ready yet after local forfeit.
  String? _forcedResultCode;
  String? get forcedResultCode => _forcedResultCode;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  String? _currentInviteId;
  String? get currentInviteId => _currentInviteId;

  String? get activeMatchId => _activeMatchId;

  String get currentOpponentName {
    final participants =
        _currentMatch?.participants ?? <PvpParticipantResponse>[];
    for (final participant in participants) {
      if (_isMyParticipant(participant)) continue;
      final name = participant.displayName?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return '';
  }

  bool _isMyParticipant(PvpParticipantResponse participant) {
    final userId = _currentUserId;
    if (userId != null &&
        userId.isNotEmpty &&
        participant.userId != null &&
        participant.userId == userId) {
      return true;
    }
    return false;
  }

  PvpParticipantResponse? get _myParticipant {
    final participants = _currentMatch?.participants;
    if (participants == null) return null;
    for (final p in participants) {
      if (_isMyParticipant(p)) return p;
    }
    for (final p in participants) {
      if (p.participantTypeCode.toLowerCase() == 'user' &&
          p.userId != null &&
          p.userId!.isNotEmpty) {
        return p;
      }
    }
    return null;
  }

  void _setCurrentMatchSnapshot(PvpMatchResponse match) {
    _currentMatch = match;
    _applyHudFromMatch(match);
  }

  void _applyHudFromMatch(PvpMatchResponse match) {
    PvpParticipantResponse? me;
    PvpParticipantResponse? opponent;
    for (final p in match.participants) {
      if (_isMyParticipant(p)) {
        me = p;
      } else {
        opponent ??= p;
      }
    }
    if (me == null) {
      for (final p in match.participants) {
        if (p.participantTypeCode.toLowerCase() == 'user' &&
            p.userId != null &&
            p.userId!.isNotEmpty) {
          me = p;
          break;
        }
      }
    }
    if (opponent == null || identical(opponent, me)) {
      for (final p in match.participants) {
        if (!identical(p, me)) {
          opponent = p;
          break;
        }
      }
    }

    // Do nothing here, we will smoothly update _myProgress and _opponentProgress in _updateRaceProgress()
  }

  void _applyProgressDetails(Map<String, dynamic> details) {
    final rawParticipants = details['participants'];
    if (rawParticipants is! List || rawParticipants.isEmpty) {
      return;
    }

    final match = _currentMatch;
    if (match == null) return;

    final updatesById = <String, Map<String, dynamic>>{};
    for (final item in rawParticipants) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      final id = row['matchPlayerId']?.toString();
      if (id == null || id.isEmpty) continue;
      updatesById[id] = row;
    }
    if (updatesById.isEmpty) return;

    final updated = match.participants.map((p) {
      final id = p.matchPlayerId;
      if (id == null || id.isEmpty) return p;
      final row = updatesById[id];
      if (row == null) return p;

      final distance = (row['distanceUnits'] as num?)?.toInt();
      print('[PvP][match.progress][apply] participant=$id distance=$distance');
      return p.copyWith(
        distanceUnits: distance,
        validatedSteps: (row['validatedSteps'] as num?)?.toInt(),
        speedMultiplierBps: (row['speedMultiplierBps'] as num?)?.toInt(),
        score: (row['score'] as num?)?.toInt(),
      );
    }).toList();

    _currentMatch = PvpMatchResponse(
      matchId: match.matchId,
      matchTypeCode: match.matchTypeCode,
      statusCode: match.statusCode,
      sourceCode: match.sourceCode,
      serverTime: match.serverTime,
      createdAt: match.createdAt,
      countdownStartsAt: match.countdownStartsAt,
      countdownEndsAt: match.countdownEndsAt,
      countdownSecondsRemaining: match.countdownSecondsRemaining,
      startedAt: match.startedAt,
      endedAt: match.endedAt,
      settlementEndsAt: match.settlementEndsAt,
      lastEventSequence: match.lastEventSequence,
      participants: updated,
    );
    _applyHudFromMatch(_currentMatch!);
    notifyListeners();
  }

  void _logSignalREvent(
    Map<String, dynamic> event, {
    required String eventType,
  }) {}

  DateTime estimatedServerNow() {
    final localNow = DateTime.now().toUtc();
    if (_serverOffset == null) {
      return localNow;
    }
    return localNow.add(_serverOffset!);
  }

  void _applyCountdownSchedule({
    required DateTime countdownStartsAt,
    required DateTime countdownEndsAt,
    required DateTime serverTime,
  }) {
    final localNow = DateTime.now().toUtc();
    final serverOffset = serverTime.difference(localNow);

    _countdownStartsAt = countdownStartsAt.toUtc();
    _countdownEndsAt = countdownEndsAt.toUtc();
    _serverOffset = serverOffset;
    _countdownActive = true;
    _lastLoggedCountdownValue = null;
    debugPrint(
      '[PvP] Countdown scheduled starts=$_countdownStartsAt ends=$_countdownEndsAt offset=$serverOffset',
    );
    _updateState(PvpMatchmakingState.countdown, reason: 'countdown schedule');
  }

  void _stopCountdownSchedule() {
    _countdownTicker?.cancel();
    _countdownTicker = null;
    _countdownActive = false;
    _countdownStartsAt = null;
    _countdownEndsAt = null;
    _lastLoggedCountdownValue = null;
  }

  int calculateCountdown() {
    final phase = resolveCountdownPhase(
      countdownActive: _countdownActive,
      countdownStartsAt: _countdownStartsAt,
      countdownEndsAt: _countdownEndsAt,
      serverNow: estimatedServerNow(),
    );

    if (phase != PvpCountdownPhase.countdown) {
      return 0;
    }

    final serverNow = estimatedServerNow();
    final remainingMilliseconds = _countdownEndsAt!
        .difference(serverNow)
        .inMilliseconds;

    return (remainingMilliseconds / 1000).ceil().clamp(1, 5);
  }

  int get countdownSecondsRemaining => calculateCountdown();

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    if (!_countdownActive ||
        _countdownStartsAt == null ||
        _countdownEndsAt == null ||
        _matchmakingState != PvpMatchmakingState.countdown) {
      return;
    }

    _countdownTicker = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      final phase = resolveCountdownPhase(
        countdownActive: _countdownActive,
        countdownStartsAt: _countdownStartsAt,
        countdownEndsAt: _countdownEndsAt,
        serverNow: estimatedServerNow(),
      );

      if (phase == PvpCountdownPhase.finished) {
        timer.cancel();
        cancelCountdownTimer(reason: 'timer finished', matchId: _activeMatchId);
        if (_lastLoggedCountdownValue != 0) {
          _lastLoggedCountdownValue = 0;
          debugPrint('[PvP] Countdown finished → GO');
        }
        notifyListeners();
        return;
      }

      if (phase == PvpCountdownPhase.countdown) {
        final remaining = countdownSecondsRemaining;
        if (_lastLoggedCountdownValue != remaining) {
          _lastLoggedCountdownValue = remaining;
          debugPrint('[PvP] Countdown=$remaining');
        }
        notifyListeners();
      }
    });
  }

  void _stopCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = null;
  }

  void _stopRaceTicker() {
    _raceTicker?.cancel();
    _raceTicker = null;
  }

  bool get isRaceRunning =>
      _matchmakingState == PvpMatchmakingState.running && !_isRaceFinished;

  bool get isRaceFinished =>
      _isRaceFinished || _matchmakingState == PvpMatchmakingState.finished;

  double get myProgress => _myProgress;

  double get opponentProgress => _opponentProgress;

  double get raceTimeProgress => _raceTimeProgress;

  String get racePhase {
    if (_matchmakingState == PvpMatchmakingState.countdown) {
      final phase = resolveCountdownPhase(
        countdownActive: _countdownActive,
        countdownStartsAt: _countdownStartsAt,
        countdownEndsAt: _countdownEndsAt,
        serverNow: estimatedServerNow(),
      );
      if (phase == PvpCountdownPhase.countdown) {
        return '$countdownSecondsRemaining';
      }
      if (phase == PvpCountdownPhase.beforeStart) {
        return 'ready';
      }
      // Local countdown ended; wait for match.started while showing GO.
      return 'go';
    }
    if (_matchmakingState == PvpMatchmakingState.running && !_isRaceFinished) {
      return 'running';
    }
    if (_matchmakingState == PvpMatchmakingState.finished || _isRaceFinished) {
      return 'finished';
    }
    return 'ready';
  }

  Duration get elapsed {
    if (_raceStartedAt == null) return Duration.zero;
    final serverNow = estimatedServerNow();
    final elapsed = serverNow.difference(_raceStartedAt!);
    if (elapsed.isNegative) return Duration.zero;
    return elapsed > _raceDuration ? _raceDuration : elapsed;
  }

  Duration get totalDuration => _raceDuration;

  void _resetRaceState() {
    _raceStartedAt = null;
    _raceTimeProgress = 0.0;
    _myProgress = 0.0;
    _opponentProgress = 0.0;
    _isRaceFinished = false;
    _stopRaceTicker();
    _stopSettlementPoll();
  }

  void _stopSettlementPoll() {
    _settlementPollTimer?.cancel();
    _settlementPollTimer = null;
  }

  void _cancelMatchmakingRecoveryTimer() {
    _matchmakingRecoveryTimer?.cancel();
    _matchmakingRecoveryTimer = null;
  }

  int _beginMatchmakingSession() {
    _cancelMatchmakingRecoveryTimer();
    return ++_matchmakingSessionGeneration;
  }

  void _stopMatchmakingRecovery() {
    _cancelMatchmakingRecoveryTimer();
    _matchmakingSessionGeneration++;
  }

  bool _isCurrentMatchmakingSession(int session) =>
      session == _matchmakingSessionGeneration;

  bool _shouldContinueMatchmakingRecovery(int session) {
    if (!_isCurrentMatchmakingSession(session)) return false;
    if (_matchmakingState == PvpMatchmakingState.connecting) return true;
    if (_matchmakingState == PvpMatchmakingState.waiting) {
      final status = _currentMatch?.statusCode.toLowerCase();
      return _currentMatch == null ||
          status == null ||
          status == 'waiting' ||
          (status == 'countdown' && _countdownEndsAt == null);
    }
    return _activeMatchId != null &&
        _activeMatchId!.isNotEmpty &&
        !_hasMatchRoomJoined &&
        (_matchmakingState == PvpMatchmakingState.countdown ||
            _matchmakingState == PvpMatchmakingState.running);
  }

  void _scheduleMatchmakingRecovery(int session, {required Duration delay}) {
    if (!_shouldContinueMatchmakingRecovery(session)) return;
    _cancelMatchmakingRecoveryTimer();
    _matchmakingRecoveryTimer = Timer(delay, () {
      _matchmakingRecoveryTimer = null;
      unawaited(_runMatchmakingRecovery(session));
    });
  }

  Future<void> _runMatchmakingRecovery(int session) async {
    if (!_shouldContinueMatchmakingRecovery(session)) return;
    if (_matchmakingRecoveryInFlight) {
      _scheduleMatchmakingRecovery(
        session,
        delay: _matchmakingRecoveryInterval,
      );
      return;
    }

    _matchmakingRecoveryInFlight = true;
    try {
      final shouldRetry = await _recoverMatchmakingStateFromStatus(
        session: session,
      );
      if (shouldRetry && _shouldContinueMatchmakingRecovery(session)) {
        _scheduleMatchmakingRecovery(
          session,
          delay: _matchmakingRecoveryInterval,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[PvP] matchmaking recovery failed: $error\n$stackTrace');
      if (_shouldContinueMatchmakingRecovery(session)) {
        _scheduleMatchmakingRecovery(
          session,
          delay: _matchmakingRecoveryInterval,
        );
      }
    } finally {
      _matchmakingRecoveryInFlight = false;
    }
  }

  void _updateRaceProgress() {
    if (_raceStartedAt == null) return;

    final elapsedMs = elapsed.inMilliseconds;
    final totalMs = _raceDuration.inMilliseconds;
    final progress = totalMs == 0 ? 0.0 : elapsedMs / totalMs;
    _raceTimeProgress = progress.clamp(0.0, 1.0);

    // UC-72: HUD mượt mà kết hợp giữa Server Distance và Time Progress
    final me = _myParticipant;
    PvpParticipantResponse? opponent;
    final participants = _currentMatch?.participants ?? [];
    for (final p in participants) {
      if (me == null || p.matchPlayerId != me.matchPlayerId) {
        opponent = p;
        break;
      }
    }

    final myDist = me?.distanceUnits ?? 0;
    final oppDist = opponent?.distanceUnits ?? 0;

    if (myDist <= 0 && oppDist <= 0) {
      _myProgress = _raceTimeProgress * 100.0;
      _opponentProgress = _raceTimeProgress * 100.0;
    } else {
      final scale = math.max(math.max(myDist, oppDist), 1);
      _myProgress = ((myDist / scale) * _raceTimeProgress * 100)
          .clamp(0, 100)
          .toDouble();
      _opponentProgress = ((oppDist / scale) * _raceTimeProgress * 100)
          .clamp(0, 100)
          .toDouble();
    }
  }

  void _startRaceTicker() {
    _stopRaceTicker();
    _raceTicker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateRaceProgress();
      notifyListeners();
      if (_raceTimeProgress >= 1.0) {
        timer.cancel();
        // Local HUD clock ended — do not invent win/MMR. Poll server until
        // finished/cancelled, then UC-69 result becomes available.
        _isRaceFinished = true;
        notifyListeners();
        unawaited(_pollMatchUntilTerminal());
      }
    });
  }

  Future<void> _pollMatchUntilTerminal() async {
    final matchId = _activeMatchId;
    if (matchId == null || matchId.isEmpty) return;
    if (_matchmakingState == PvpMatchmakingState.finished ||
        _matchmakingState == PvpMatchmakingState.cancelled) {
      if (_matchResult == null &&
          _matchmakingState == PvpMatchmakingState.finished) {
        await loadMatchResult(matchId);
      }
      return;
    }

    _stopSettlementPoll();
    var attempts = 0;
    _settlementPollTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      attempts++;
      if (attempts > 30 ||
          _matchmakingState == PvpMatchmakingState.finished ||
          _matchmakingState == PvpMatchmakingState.cancelled ||
          _activeMatchId != matchId) {
        timer.cancel();
        if (_settlementPollTimer == timer) {
          _settlementPollTimer = null;
        }
        return;
      }

      try {
        final response = await _pvpDatasource.getMatch(matchId);
        if (!response.success || response.data == null) return;

        final status = response.data!.statusCode.toLowerCase();
        _setCurrentMatchSnapshot(response.data!);

        if (status == 'finished') {
          timer.cancel();
          if (_settlementPollTimer == timer) {
            _settlementPollTimer = null;
          }
          _isRaceFinished = true;
          _updateState(
            PvpMatchmakingState.finished,
            reason: 'settlement poll finished',
          );
          await loadMatchResult(matchId);
          return;
        }

        if (status == 'cancelled') {
          timer.cancel();
          if (_settlementPollTimer == timer) {
            _settlementPollTimer = null;
          }
          _updateState(
            PvpMatchmakingState.cancelled,
            reason: 'settlement poll cancelled',
          );
          return;
        }

        if (status == 'settling') {
          _updateState(
            PvpMatchmakingState.waiting,
            reason: 'settlement poll settling',
          );
        }
      } catch (e, st) {
        debugPrint('[PvP] settlement poll failed: $e\n$st');
      }
    });
  }

  void _startRace({PvpMatchResponse? match}) {
    _resetRaceState();

    // UC-72: Tính thời gian đua từ server time (startedAt + endedAt).
    // Fallback về server estimate clock + 30s nếu BE không cung cấp.
    final serverStarted = match?.startedAt;
    final serverEnded = match?.endedAt;

    if (serverStarted != null && serverEnded != null) {
      final raceTotalMs = serverEnded.difference(serverStarted).inMilliseconds;
      _raceDuration = Duration(
        milliseconds: raceTotalMs > 0 ? raceTotalMs : 30000,
      );
      _raceStartedAt = serverStarted.toUtc();
    } else if (serverStarted != null) {
      _raceDuration = const Duration(seconds: 30);
      _raceStartedAt = serverStarted.toUtc();
    } else {
      _raceDuration = const Duration(seconds: 30);
      _raceStartedAt = estimatedServerNow();
    }

    _updateRaceProgress();
    notifyListeners();
    _startRaceTicker();
  }

  void clearMatchState() {
    _stopMatchmakingRecovery();
    _currentMatch = null;
    _activeMatchId = null;
    _matchResult = null;
    _lastClaimResponse = null;
    _forcedResultCode = null;
    _hasMatchRoomJoined = false;
    _serverOffset = null;
    _countdownStartsAt = null;
    _countdownEndsAt = null;
    _countdownActive = false;
    _resetRaceState();
    cancelCountdownTimer(reason: 'clearMatchState', matchId: _activeMatchId);
    _updateState(PvpMatchmakingState.idle, reason: 'clearMatchState');
  }

  Future<void> initializeSignalR() {
    if (_signalRInitialized) return Future<void>.value();
    final current = _signalRInitialization;
    if (current != null) return current;

    final future = _initializeSignalR();
    _signalRInitialization = future;
    return future.whenComplete(() {
      if (identical(_signalRInitialization, future)) {
        _signalRInitialization = null;
      }
    });
  }

  Future<void> _initializeSignalR() async {
    _signalRService.setEventHandlers(
      onAssigned: (event) => unawaited(handleSignalREvent(event)),
      onProgress: (event) => unawaited(handleSignalREvent(event)),
      onFinished: (event) => unawaited(handleSignalREvent(event)),
      onSettling: (event) => unawaited(handleSignalREvent(event)),
      onCancelled: (event) => unawaited(handleSignalREvent(event)),
      onCountdownStarted: (event) => unawaited(handleSignalREvent(event)),
      onStarted: (event) => unawaited(handleSignalREvent(event)),
      onForfeited: (event) => unawaited(handleSignalREvent(event)),
      onPresenceChanged: (event) => _handlePresenceChanged(event),
      onQueueFailed: (event) => unawaited(handleSignalREvent(event)),
    );

    // When SignalR reconnects, recover authoritative matchmaking state
    // và refresh friends + invites để lấy snapshot presence mới nhất.
    _signalRService.setReconnectedHandler(() async {
      _log('SignalR reconnected - recovering matchmaking status');
      final shouldRetry = await _recoverMatchmakingStateFromStatus(
        session: _matchmakingSessionGeneration,
      );
      if (shouldRetry) {
        _scheduleMatchmakingRecovery(
          _matchmakingSessionGeneration,
          delay: _matchmakingRecoveryInterval,
        );
      }
      // Refresh friends list and pending invites after reconnect.
      await _refreshPresenceSnapshots();
    });

    // If using the default implementation, print debug info about token and negotiate URL
    try {
      if (_signalRService is DefaultPvpSignalRService) {
        await _signalRService.debugLogAccessTokenAndNegotiateInfo();
      }
    } catch (e) {
      _log('Failed to run SignalR debug logs: $e');
    }

    await _signalRService.connect();
    _hasMatchRoomJoined = _signalRService.isMatchRoomJoined;
    _log('SignalR Connected (initializeSignalR)');
    _log('Hub URL: ${_signalRService.hubUrl ?? 'unknown'}');
    _log('ConnectionId: ${_signalRService.connectionId ?? 'unknown'}');
    // mark as initialized so callers can await this completion
    _signalRInitialized = true;
  }

  bool _signalRInitialized = false;

  Future<void> _handlePresenceHubEvent(Map<String, dynamic> event) async {
    final eventType =
        event['eventType']?.toString() ??
        event['_receivedMethod']?.toString() ??
        '';

    if (eventType == 'presence.changed') {
      _handlePresenceChanged(event);
      return;
    }

    if (eventType.startsWith('invite.')) {
      if (eventType == 'invite.declined') {
        _inviteDeclined = true;
        _updateState(PvpMatchmakingState.idle);
      }
      await _refreshPresenceSnapshots();
      return;
    }

    if (eventType == 'queue.failed' ||
        eventType == 'match.assigned' ||
        eventType == 'match.forfeited' ||
        eventType == 'match.finished' ||
        eventType == 'match.cancelled') {
      if (!_signalRInitialized) {
        try {
          await initializeSignalR();
        } catch (error) {
          debugPrint(
            '[PvP] Cannot connect SprintHub after PresenceHub $eventType: $error',
          );
          return;
        }
      }
      await handleSignalREvent(event);
      if (eventType == 'match.assigned') {
        _presenceProvider?.clearLatestMatchAssignedEvent(
          event['eventId']?.toString(),
        );
      }
    }
  }

  Future<void> fetchWaitingRoomData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _petDatasource.getPetName(),
        _petDatasource.getPetStatus(),
        _petDatasource.getPetOverview(),
        _activityDatasource.getStatistic(ActivityStatsRange.daily),
        _friendsDatasource.getFriends(),
        _pvpDatasource.getIncomingInvites(),
        _pvpDatasource.getMatchHistory(includeActive: false),
      ]);

      final petNameResp = futures[0] as dynamic;
      final petStatusResp = futures[1] as dynamic;
      final petOverviewResp = futures[2] as dynamic;
      final activityResp = futures[3] as dynamic;
      final friendsResp = futures[4] as List<FriendsResponse>;
      final invitesResp = futures[5] as dynamic;
      final historyResp = futures[6] as dynamic;

      if (petNameResp.success && petNameResp.data != null) {
        _petName = petNameResp.data!.petName;
      }

      if (petStatusResp.success && petStatusResp.data != null) {
        _currentEnergy = petStatusResp.data!.currentEnergy;
        _maxEnergy = petStatusResp.data!.maxEnergy;
        _currentBond = petStatusResp.data!.currentBond;
      }

      if (petOverviewResp.success && petOverviewResp.data != null) {
        final overview = petOverviewResp.data!;
        final code = overview.affinityCode.trim();
        if (code.isNotEmpty) {
          _spiritAffinityCode = code;
        }
        _petStageNo = overview.stageNo;
        final formName = overview.formName.trim();
        _spiritAffinityLabel = formName;
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
        final page = historyResp.data as PvpMatchHistoryPage;
        _matchHistory = List<PvpMatchResponse>.from(page.items);
        _historyPage = page.page;
        _historyTotal = page.total;
      }
    } catch (e) {
      debugPrint('Error fetching PvP waiting room data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _log(String message, {String? matchId}) {
    // Keep quiet by default; use targeted debugPrint for countdown lifecycle only.
  }

  void _enterRunning({
    required String reason,
    String? matchId,
    PvpMatchResponse? match,
  }) {
    _stopCountdownSchedule();
    _updateState(PvpMatchmakingState.running, reason: reason);
    _startRace(match: match ?? _currentMatch);
  }

  void startRace({required String reason, String? matchId}) {
    if (_matchmakingState == PvpMatchmakingState.running && !_isRaceFinished) {
      return;
    }
    _enterRunning(reason: reason, matchId: matchId);
  }

  void stopCountdown({required String reason, String? matchId}) {
    _stopCountdownSchedule();
  }

  void cancelCountdownTimer({required String reason, String? matchId}) {
    _stopCountdownTicker();
  }

  void _updateState(PvpMatchmakingState state, {String reason = 'other'}) {
    _matchmakingState = state;
    if (_matchmakingState == PvpMatchmakingState.countdown) {
      _startCountdownTicker();
    } else {
      _stopCountdownTicker();
    }
    notifyListeners();
  }

  Future<bool> _joinAndSyncMatch(String matchId) async {
    _activeMatchId = matchId;
    _log('GET Match', matchId: matchId);
    final matchResponse = await _pvpDatasource.getMatch(matchId);
    if (!matchResponse.success || matchResponse.data == null) {
      debugPrint('GET match failed after assigned: ${matchResponse.message}');
      return false;
    }

    final match = matchResponse.data!;
    _setCurrentMatchSnapshot(match);
    _lastSequences[matchId] = match.lastEventSequence ?? 0;

    final normalizedStatus = match.statusCode.toLowerCase();
    if (normalizedStatus == 'countdown' &&
        match.countdownStartsAt != null &&
        match.countdownEndsAt != null) {
      _applyCountdownSchedule(
        countdownStartsAt: match.countdownStartsAt!,
        countdownEndsAt: match.countdownEndsAt!,
        serverTime: match.serverTime ?? DateTime.now().toUtc(),
      );
      return true;
    }

    if (normalizedStatus == 'running') {
      _stopCountdownSchedule();
      if (_matchmakingState != PvpMatchmakingState.running ||
          _raceStartedAt == null) {
        startRace(reason: 'match snapshot running', matchId: matchId);
      } else {
        _applyHudFromMatch(match);
        notifyListeners();
      }
      return true;
    }

    if (normalizedStatus == 'settling') {
      _stopCountdownSchedule();
      _updateState(
        PvpMatchmakingState.waiting,
        reason: 'match snapshot settling',
      );
      return true;
    }

    if (normalizedStatus == 'finished') {
      _stopCountdownSchedule();
      _isRaceFinished = true;
      _updateState(
        PvpMatchmakingState.finished,
        reason: 'match snapshot finished',
      );
      await loadMatchResult(matchId);
      return true;
    }

    if (normalizedStatus == 'cancelled') {
      _stopCountdownSchedule();
      _updateState(
        PvpMatchmakingState.cancelled,
        reason: 'match snapshot cancelled',
      );
      return true;
    }

    _stopCountdownSchedule();
    _updateState(PvpMatchmakingState.waiting, reason: 'match snapshot waiting');
    return true;
  }

  PvpMatchmakingState _mapStatusCodeToState(String statusCode) {
    switch (statusCode.toLowerCase()) {
      case 'countdown':
        return PvpMatchmakingState.countdown;
      case 'running':
        return PvpMatchmakingState.running;
      case 'settling':
        return PvpMatchmakingState.waiting;
      case 'waiting':
        return PvpMatchmakingState.waiting;
      default:
        return PvpMatchmakingState.idle;
    }
  }

  Future<bool> _joinAndPrepareMatch(String matchId) async {
    _activeMatchId = matchId;
    bool joined = false;
    try {
      _log('Joining room...', matchId: matchId);
      joined = await _signalRService.joinMatch(matchId);
      _log('JoinMatch ${joined ? 'success' : 'failed'}', matchId: matchId);
    } catch (error, stackTrace) {
      debugPrint('[PvP] JoinMatch recovery failed: $error\n$stackTrace');
    }
    _hasMatchRoomJoined = joined;

    final synced = await _joinAndSyncMatch(matchId);
    if (!synced) return false;

    if (joined && _currentMatch?.statusCode.toLowerCase() == 'countdown') {
      try {
        final readyResponse = await _signalRService.readyMatch(matchId);
        final allReady = readyResponse['allReady'] as bool? ?? false;
        final readyStartsAt = readyResponse['countdownStartsAt'] as String?;
        final readyEndsAt = readyResponse['countdownEndsAt'] as String?;
        final readyServerTime = readyResponse['serverTime'] as String?;
        debugPrint(
          '[PvP] Recovery ReadyMatch allReady=$allReady matchId=$matchId',
        );
        if (allReady &&
            readyStartsAt != null &&
            readyEndsAt != null &&
            readyServerTime != null) {
          _applyCountdownSchedule(
            countdownStartsAt: DateTime.parse(readyStartsAt).toUtc(),
            countdownEndsAt: DateTime.parse(readyEndsAt).toUtc(),
            serverTime: DateTime.parse(readyServerTime).toUtc(),
          );
        }
      } catch (error, stackTrace) {
        debugPrint('[PvP] Recovery ReadyMatch failed: $error\n$stackTrace');
      }
    }

    return joined;
  }

  Future<bool> _recoverMatchmakingStateFromStatus({int? session}) async {
    _log('GET Matchmaking Status');
    final statusResponse = await _pvpDatasource.getMatchmakingStatus();
    if (session != null && !_isCurrentMatchmakingSession(session)) return false;
    if (!statusResponse.success) {
      _log(
        'Matchmaking status request failed; keeping current state for retry '
        '(status=${statusResponse.status})',
      );
      return session != null;
    }
    if (statusResponse.data == null) {
      _stopMatchmakingRecovery();
      _currentMatch = null;
      _activeMatchId = null;
      _updateState(PvpMatchmakingState.idle);
      return false;
    }

    final status = statusResponse.data!;
    if (status.matchId != null && status.matchId!.isNotEmpty) {
      _log(
        'GET Matchmaking Status returned active match',
        matchId: status.matchId!,
      );

      final matchId = status.matchId!;
      await _joinAndPrepareMatch(matchId);
      if (session != null && !_isCurrentMatchmakingSession(session))
        return false;
      return session != null && _shouldContinueMatchmakingRecovery(session);
    }

    final nextState = _mapStatusCodeToState(status.statusCode);
    if (nextState == PvpMatchmakingState.idle) {
      _stopMatchmakingRecovery();
      _currentMatch = null;
      _activeMatchId = null;
    }
    _updateState(nextState);
    return session != null && _shouldContinueMatchmakingRecovery(session);
  }

  Future<void> handleSignalREvent(Map<String, dynamic> event) async {
    final eventType = event['eventType']?.toString() ?? 'unknown';
    final eventId = event['eventId']?.toString();
    final payload =
        event['payload'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final matchId =
        payload['matchId']?.toString() ?? event['aggregateId']?.toString();

    final payloadSequence =
        payload['sequence'] as int? ?? event['sequence'] as int?;
    final lastSequence = matchId != null ? _lastSequences[matchId] : null;

    // dedupe
    if (eventId != null && _processedEventIds.contains(eventId)) {
      return;
    }

    if (payloadSequence != null &&
        lastSequence != null &&
        payloadSequence <= lastSequence) {
      return;
    }

    if (eventId != null) {
      _processedEventIds.add(eventId);
    }
    if (payloadSequence != null && matchId != null) {
      _lastSequences[matchId] = payloadSequence;
    }

    _logSignalREvent(event, eventType: eventType);

    if (eventType == 'queue.failed') {
      if (_matchmakingState == PvpMatchmakingState.waiting ||
          _matchmakingState == PvpMatchmakingState.connecting) {
        _log('queue.failed: matchmaking ended without an eligible bot');
        _stopMatchmakingRecovery();
        _currentMatch = null;
        _activeMatchId = null;
        _hasMatchRoomJoined = false;
        _updateState(PvpMatchmakingState.idle, reason: 'queue.failed');
      }
      return;
    }

    // Handle specific events
    if (eventType == 'match.assigned') {
      _hasReceivedAssignedEvent = true;
      if (matchId != null && matchId.isNotEmpty) {
        _log('match.assigned', matchId: matchId);
        _traceMatchmaking('[8] Recover assigned match');
        final joined = await _joinAndPrepareMatch(matchId);
        if (!joined ||
            _shouldContinueMatchmakingRecovery(_matchmakingSessionGeneration)) {
          _scheduleMatchmakingRecovery(
            _matchmakingSessionGeneration,
            delay: _matchmakingRecoveryInterval,
          );
        } else {
          _stopMatchmakingRecovery();
        }
      } else {
        _log('match.assigned without matchId');
        _traceMatchmaking('stopped at: assigned without matchId');
      }
      return;
    }

    if (eventType == 'match.countdown.started') {
      final details = payload['details'] as Map<String, dynamic>?;
      final startsAt = details?['countdownStartsAt'] as String?;
      final endsAt = details?['countdownEndsAt'] as String?;
      final serverTimeValue = payload['serverTime'] as String?;
      if (matchId != null &&
          matchId.isNotEmpty &&
          startsAt != null &&
          endsAt != null &&
          serverTimeValue != null) {
        debugPrint('[PvP] CountdownStarted matchId=$matchId');
        _applyCountdownSchedule(
          countdownStartsAt: DateTime.parse(startsAt).toUtc(),
          countdownEndsAt: DateTime.parse(endsAt).toUtc(),
          serverTime: DateTime.parse(serverTimeValue).toUtc(),
        );
      }
      return;
    }

    if (eventType == 'match.started') {
      debugPrint('[PvP] MatchStarted matchId=$matchId');
      startRace(reason: 'match.started event', matchId: matchId);
      return;
    }

    if (eventType == 'match.forfeited') {
      debugPrint('[PvP] MatchForfeited matchId=$matchId');
      stopCountdown(reason: 'match.forfeited', matchId: matchId);
      _stopRaceTicker();
      _isRaceFinished = true;
      final details = payload['details'] as Map<String, dynamic>?;
      final forfeitedByUserId = details?['forfeitedByUserId']?.toString();
      if (forfeitedByUserId != null && forfeitedByUserId == _currentUserId) {
        _forcedResultCode = 'lose';
      } else if (forfeitedByUserId != null) {
        _forcedResultCode = 'win';
      }
      notifyListeners();
      return;
    }

    if (eventType == 'match.progress') {
      final details = payload['details'];
      if (details is Map) {
        _applyProgressDetails(Map<String, dynamic>.from(details));
      } else if (matchId != null && matchId.isNotEmpty) {
        // Authoritative resync without restarting the race clock.
        final response = await _pvpDatasource.getMatch(matchId);
        if (response.success && response.data != null) {
          _setCurrentMatchSnapshot(response.data!);
          notifyListeners();
        }
      }
      return;
    }

    if (eventType == 'match.finished') {
      stopCountdown(reason: 'match.finished', matchId: matchId);
      _isRaceFinished = true;
      if (matchId != null && matchId.isNotEmpty) {
        // Snapshot + UC-69 result (finished branch inside _joinAndSyncMatch).
        await _joinAndSyncMatch(matchId);
        if (_matchResult == null) {
          await loadMatchResult(matchId);
        }
      }
      if (_matchmakingState != PvpMatchmakingState.finished) {
        _updateState(PvpMatchmakingState.finished, reason: 'match.finished');
      }
      return;
    }

    if (eventType == 'match.settling') {
      stopCountdown(reason: 'match.settling', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
      }
      _updateState(PvpMatchmakingState.waiting, reason: 'match.settling');
      return;
    }

    if (eventType == 'match.cancelled') {
      stopCountdown(reason: 'match.cancelled', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
      }
      _updateState(PvpMatchmakingState.cancelled, reason: 'match.cancelled');
      return;
    }
  }

  // ---------------------------------------------------------------------------
  // Presence helpers
  // ---------------------------------------------------------------------------

  /// Refresh friends list + pending invites — dùng sau reconnect để đồng bộ
  /// snapshot presence authoritative từ server.
  Future<void> _refreshPresenceSnapshots() async {
    try {
      final friendsResp = await _friendsDatasource.getFriends();
      _friendsList = friendsResp;
    } catch (e) {
      debugPrint('[PvP] _refreshPresenceSnapshots friends error: $e');
    }
    try {
      final incomingResp = await _pvpDatasource.getInvites(
        direction: 'incoming',
        status: 'pending',
      );
      if (incomingResp.success && incomingResp.data != null) {
        _incomingInvites = incomingResp.data!.items;
        _incomingInvitesTotal = incomingResp.data!.total;
      }
    } catch (e) {
      debugPrint('[PvP] _refreshPresenceSnapshots invites error: $e');
    }
    notifyListeners();
  }

  /// Handler cho SignalR event `presence.changed`.
  /// Cập nhật card bạn bè và card invite tương ứng với userId thay đổi.
  void _handlePresenceChanged(Map<String, dynamic> event) {
    // Dedupe theo eventId
    final eventId = event['eventId']?.toString();
    if (eventId != null && _processedEventIds.contains(eventId)) return;
    if (eventId != null) _processedEventIds.add(eventId);

    final payload = (event['payload'] as Map<String, dynamic>?) ?? event;

    final userId =
        payload['userId']?.toString() ?? event['aggregateId']?.toString();
    if (userId == null || userId.isEmpty) return;

    final isOnline = payload['isOnline'] == true;
    final pvpCode =
        payload['pvpAvailabilityCode'] as String? ??
        (isOnline ? 'available' : 'offline');

    debugPrint(
      '[PvP] presence.changed userId=$userId isOnline=$isOnline pvpCode=$pvpCode',
    );

    // Cập nhật friend card
    bool friendsUpdated = false;
    final updatedFriends = _friendsList.map((f) {
      if (f.userId == userId) {
        friendsUpdated = true;
        return f.copyWithPresence(
          isOnline: isOnline,
          pvpAvailabilityCode: pvpCode,
        );
      }
      return f;
    }).toList();
    if (friendsUpdated) _friendsList = updatedFriends;

    // Cập nhật invite card (incoming + sent) theo user.userId
    bool invitesUpdated = false;
    final updatedIncoming = _incomingInvites.map((inv) {
      if (inv.user.userId == userId) {
        invitesUpdated = true;
        return inv.copyWithPresence(
          isOnline: isOnline,
          pvpAvailabilityCode: pvpCode,
        );
      }
      return inv;
    }).toList();
    if (invitesUpdated) _incomingInvites = updatedIncoming;

    bool sentUpdated = false;
    final updatedSent = _sentInvites.map((inv) {
      if (inv.user.userId == userId) {
        sentUpdated = true;
        return inv.copyWithPresence(
          isOnline: isOnline,
          pvpAvailabilityCode: pvpCode,
        );
      }
      return inv;
    }).toList();
    if (sentUpdated) _sentInvites = updatedSent;

    if (friendsUpdated || invitesUpdated || sentUpdated) {
      notifyListeners();
    }
  }

  Future<void> syncMatch(String matchId) async {
    final response = await _pvpDatasource.getMatch(matchId);
    if (!response.success || response.data == null) {
      return;
    }

    final match = response.data!;
    _setCurrentMatchSnapshot(match);
    final normalizedStatus = match.statusCode.toLowerCase();
    if (normalizedStatus == 'countdown' &&
        match.countdownStartsAt != null &&
        match.countdownEndsAt != null) {
      _applyCountdownSchedule(
        countdownStartsAt: match.countdownStartsAt!,
        countdownEndsAt: match.countdownEndsAt!,
        serverTime: match.serverTime ?? DateTime.now().toUtc(),
      );
      return;
    }

    if (normalizedStatus == 'running') {
      startRace(reason: 'syncMatch running', matchId: matchId);
      return;
    }

    if (normalizedStatus == 'settling') {
      _updateState(PvpMatchmakingState.waiting, reason: 'syncMatch settling');
      return;
    }

    if (normalizedStatus == 'finished') {
      _isRaceFinished = true;
      _updateState(PvpMatchmakingState.finished);
      await loadMatchResult(matchId);
      return;
    }

    if (normalizedStatus == 'cancelled') {
      _updateState(PvpMatchmakingState.cancelled);
      return;
    }

    _updateState(PvpMatchmakingState.waiting);
  }

  bool _isLoadingMatchResult = false;

  Future<void> loadMatchResult(String matchId, {int maxAttempts = 3}) async {
    if (_isLoadingMatchResult) return;
    _isLoadingMatchResult = true;
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final response = await _pvpDatasource.getMatchResult(matchId);
        if (response.success && response.data != null) {
          _matchResult = response.data!;
          _setCurrentMatchSnapshot(_matchResult!.match);
          notifyListeners();
          return;
        }

        // UC-69: result only available after finished; earlier calls return 409.
        if (response.status == 409 && attempt < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }

        debugPrint(
          '[PvP] loadMatchResult failed matchId=$matchId '
          'status=${response.status} message=${response.message}',
        );
        return;
      }
    } finally {
      _isLoadingMatchResult = false;
    }
  }

  Future<bool> claimMatchReward(String matchId) async {
    final response = await _pvpDatasource.claimMatchReward(matchId);
    if (response.success && response.data != null) {
      _lastClaimResponse = response.data;
      notifyListeners();
      await loadMatchResult(matchId);
      return true;
    }

    // Retry-safe: 409 already claimed → refresh result; claimedAt means success.
    if (response.status == 409) {
      await loadMatchResult(matchId);
      return _matchResult?.claimedAt != null;
    }

    debugPrint(
      '[PvP] claimMatchReward failed matchId=$matchId '
      'status=${response.status} message=${response.message}',
    );
    return false;
  }

  /// Quit mid-race via X: current user loses, opponent wins.
  Future<bool> forfeitMatch() async {
    final matchId = _activeMatchId;
    if (matchId == null || matchId.isEmpty) {
      return false;
    }
    if (_matchmakingState == PvpMatchmakingState.finished ||
        _matchmakingState == PvpMatchmakingState.cancelled) {
      return true;
    }

    _stopRaceTicker();
    _stopSettlementPoll();
    _isRaceFinished = true;
    _forcedResultCode = 'lose';
    notifyListeners();

    final response = await _pvpDatasource.forfeitMatch(matchId);
    if (response.success && response.data != null) {
      _setCurrentMatchSnapshot(response.data!);
      final status = response.data!.statusCode.toLowerCase();
      if (status == 'finished') {
        _updateState(PvpMatchmakingState.finished, reason: 'forfeit finished');
        await loadMatchResult(matchId);
        if (_matchResult != null) {
          _forcedResultCode = null;
        } else {
          _applyLocalForfeitResult();
        }
        return true;
      }
    }

    // 409 = state already moved; resync authoritative match/result.
    if (response.status == 409) {
      await _joinAndSyncMatch(matchId);
      if (_matchmakingState == PvpMatchmakingState.finished) {
        if (_matchResult == null) {
          await loadMatchResult(matchId);
        }
        if (_matchResult != null) {
          _forcedResultCode = null;
        } else {
          _applyLocalForfeitResult();
        }
        return true;
      }
    }

    debugPrint(
      '[PvP] forfeitMatch API status=${response.status} '
      'message=${response.message} — applying local lose',
    );

    _applyLocalForfeitResult();
    _updateState(PvpMatchmakingState.finished, reason: 'forfeit local');
    return true;
  }

  void _applyLocalForfeitResult() {
    final match = _currentMatch;
    if (match == null) {
      _forcedResultCode = 'lose';
      return;
    }

    final me = _myParticipant;
    final updatedParticipants = match.participants.map((p) {
      final isMe = me != null
          ? ((p.matchPlayerId != null &&
                    me.matchPlayerId != null &&
                    p.matchPlayerId == me.matchPlayerId) ||
                (p.userId != null &&
                    me.userId != null &&
                    p.userId == me.userId) ||
                identical(p, me))
          : _isMyParticipant(p);
      return p.copyWith(resultCode: isMe ? 'lose' : 'win');
    }).toList();

    // Ensure exactly one lose for me if identification failed.
    final hasLose = updatedParticipants.any(
      (p) => p.resultCode?.toLowerCase() == 'lose',
    );
    final participants = hasLose
        ? updatedParticipants
        : [
            for (var i = 0; i < updatedParticipants.length; i++)
              i == 0
                  ? updatedParticipants[i].copyWith(resultCode: 'lose')
                  : updatedParticipants[i].copyWith(resultCode: 'win'),
          ];

    final forfeitedMatch = PvpMatchResponse(
      matchId: match.matchId,
      matchTypeCode: match.matchTypeCode,
      statusCode: 'finished',
      sourceCode: match.sourceCode,
      serverTime: match.serverTime,
      createdAt: match.createdAt,
      countdownStartsAt: match.countdownStartsAt,
      countdownEndsAt: match.countdownEndsAt,
      countdownSecondsRemaining: match.countdownSecondsRemaining,
      startedAt: match.startedAt,
      endedAt: DateTime.now().toUtc(),
      settlementEndsAt: match.settlementEndsAt,
      lastEventSequence: match.lastEventSequence,
      participants: participants,
    );

    _currentMatch = forfeitedMatch;
    _matchResult = PvpMatchResultResponse(
      match: forfeitedMatch,
      mmrBefore: 0,
      mmrDelta: 0,
      mmrAfter: 0,
      tierChanged: false,
      canClaimReward: false,
      claimedAt: null,
    );
    _forcedResultCode = 'lose';
    notifyListeners();
  }

  Future<void> startMatchmaking() async {
    if (_matchmakingState == PvpMatchmakingState.connecting ||
        _matchmakingState == PvpMatchmakingState.waiting ||
        _matchmakingState == PvpMatchmakingState.countdown ||
        _matchmakingState == PvpMatchmakingState.running) {
      return;
    }

    final session = _beginMatchmakingSession();
    _matchmakingStartedAt = DateTime.now();
    _hasReceivedAssignedEvent = false;
    _hasMatchRoomJoined = false;
    _lastMatchmakingStep = 'none';

    // Ensure SignalR is initialized before sending matchmaking POST
    if (!_signalRInitialized) {
      _log('SignalR not initialized. Initializing now before matchmaking...');
      try {
        await initializeSignalR();
      } catch (e, st) {
        if (!_isCurrentMatchmakingSession(session)) return;
        _log('SignalR initialization failed before matchmaking: $e');
        debugPrint(st.toString());
        // Do not continue matchmaking if SignalR failed to initialize
        _stopMatchmakingRecovery();
        _updateState(PvpMatchmakingState.idle);
        return;
      }
    }

    // Trace step [1]
    _traceMatchmaking('[1] SignalR Connecting');
    _log('Hub URL (config): ${_signalRService.hubUrl ?? 'default'}');
    _log('SignalR currently connected: ${_signalRService.isConnected}');
    if (_signalRService.isConnected) {
      _traceMatchmaking('[2] SignalR Connected');
      _log('ConnectionId: ${_signalRService.connectionId ?? 'unknown'}');
    } else {
      _log(
        'SignalR not connected before POST; continuing and will rely on reconnect logs',
      );
    }

    _updateState(PvpMatchmakingState.connecting);
    _traceMatchmaking('[3] POST /matchmaking');

    final response = await _pvpDatasource.startMatchmaking();
    if (!_isCurrentMatchmakingSession(session)) return;
    _traceMatchmaking('[4] Response from POST /matchmaking');
    _log(
      'POST /matchmaking response: status=${response.status}, success=${response.success}, message=${response.message}',
    );
    if (!response.success) {
      if (response.status == 409) {
        final shouldRetry = await _recoverMatchmakingStateFromStatus(
          session: session,
        );
        if (shouldRetry) {
          _scheduleMatchmakingRecovery(
            session,
            delay: _matchmakingRecoveryInterval,
          );
        }
        return;
      }

      debugPrint('Matchmaking failed: ${response.message}');
      _stopMatchmakingRecovery();
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    if (response.data == null) {
      _stopMatchmakingRecovery();
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final match = response.data!;
    _currentMatch = match;

    final normalizedStatus = match.statusCode.toLowerCase();
    if (normalizedStatus == 'waiting' || match.matchId.isEmpty) {
      _updateState(PvpMatchmakingState.waiting);
      _traceMatchmaking('[5] Waiting state entered');
      _scheduleMatchmakingRecovery(session, delay: _matchmakingRecoveryDelay);
      return;
    }

    final joined = await _joinAndPrepareMatch(match.matchId);
    if (!_isCurrentMatchmakingSession(session)) return;
    if (joined && !_shouldContinueMatchmakingRecovery(session)) {
      _stopMatchmakingRecovery();
    } else {
      _scheduleMatchmakingRecovery(
        session,
        delay: _matchmakingRecoveryInterval,
      );
    }
  }

  Future<void> cancelMatchmaking() async {
    _log('DELETE Matchmaking');
    _stopMatchmakingRecovery();
    if (_matchmakingState != PvpMatchmakingState.waiting) {
      return;
    }

    final response = await _pvpDatasource.cancelMatchmaking();
    if (response.success) {
      final activeMatchId = _activeMatchId;
      _currentMatch = null;
      _activeMatchId = null;
      _hasMatchRoomJoined = false;
      _updateState(PvpMatchmakingState.idle);
      if (activeMatchId != null) {
        unawaited(_signalRService.leaveMatch(activeMatchId));
      }
      return;
    }

    if (response.status == 404 || response.status == 409) {
      await _recoverMatchmakingStateFromStatus();
      return;
    }

    _currentMatch = null;
    _activeMatchId = null;
    _hasMatchRoomJoined = false;
    _updateState(PvpMatchmakingState.idle);
  }

  /// UC-73 — fetch incoming invites
  Future<void> fetchIncomingInvites({
    String? status = 'pending',
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _pvpDatasource.getInvites(
      direction: 'incoming',
      status: status,
      page: page,
      pageSize: pageSize,
    );
    if (response.success && response.data != null) {
      _incomingInvites = response.data!.items;
      _incomingInvitesTotal = response.data!.total;
      notifyListeners();
    }
  }

  /// UC-73 — fetch sent invites
  Future<void> fetchSentInvites({
    String? status = 'pending',
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _pvpDatasource.getInvites(
      direction: 'sent',
      status: status,
      page: page,
      pageSize: pageSize,
    );
    if (response.success && response.data != null) {
      _sentInvites = response.data!.items;
      _sentInvitesTotal = response.data!.total;
      notifyListeners();
    }
  }

  /// UC-67 — create sprint invite
  Future<PvpInviteResponse?> sendInvite(String targetUserIdOrName) async {
    String targetUserId = targetUserIdOrName;
    for (final friend in _friendsList) {
      if (friend.username.toLowerCase() == targetUserIdOrName.toLowerCase() ||
          friend.userId == targetUserIdOrName) {
        targetUserId = friend.userId;
        break;
      }
    }

    final response = await _pvpDatasource.createInvite(targetUserId);
    if (response.success && response.data != null) {
      final invite = response.data!;
      _currentInviteId = invite.inviteId;
      _updateState(PvpMatchmakingState.invitePending);
      notifyListeners();
      return invite;
    } else {
      debugPrint(
        '[PvP] createInvite failed status=${response.status}: ${response.message}',
      );
      return null;
    }
  }

  /// UC-67 — accept or decline sprint invite
  Future<PvpInviteResponse?> respondToInvite(
    String inviteId, {
    required bool accept,
  }) async {
    final response = await _pvpDatasource.respondToInvite(
      inviteId,
      accept: accept,
    );

    if (response.success && response.data != null) {
      final inviteData = response.data!;
      _incomingInvites.removeWhere((item) => item.inviteId == inviteId);
      notifyListeners();

      if (accept &&
          inviteData.matchId != null &&
          inviteData.matchId!.isNotEmpty) {
        _log('Invite accepted, joining match directly: ${inviteData.matchId}');
        await _joinAndSyncMatch(inviteData.matchId!);
      }
      return inviteData;
    } else {
      debugPrint(
        '[PvP] respondToInvite failed status=${response.status}: ${response.message}',
      );
      return null;
    }
  }

  /// UC-67 — cancel pending sprint invite
  Future<bool> cancelInvite([String? inviteId]) async {
    final targetId = inviteId ?? _currentInviteId;
    if (targetId == null || targetId.isEmpty) {
      _updateState(PvpMatchmakingState.idle);
      return false;
    }

    final response = await _pvpDatasource.cancelInvite(targetId);
    if (response.success) {
      if (_currentInviteId == targetId) {
        _currentInviteId = null;
      }
      _updateState(PvpMatchmakingState.idle);
      notifyListeners();
      return true;
    } else {
      debugPrint(
        '[PvP] cancelInvite failed status=${response.status}: ${response.message}',
      );
      _updateState(PvpMatchmakingState.idle);
      return false;
    }
  }

  void acceptChallenge(String inviteId) {
    respondToInvite(inviteId, accept: true);
  }

  void rejectChallenge(String inviteId) {
    respondToInvite(inviteId, accept: false);
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _raceTicker?.cancel();
    _settlementPollTimer?.cancel();
    _stopMatchmakingRecovery();
    unawaited(_presenceEventSubscription?.cancel());
    unawaited(_signalRService.disconnect());
    super.dispose();
  }
}
