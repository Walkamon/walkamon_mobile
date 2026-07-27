import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/pvp_realtime_service.dart';
import '../data/datasources/remote/pvp_sprint_datasource.dart';
import '../data/datasources/remote/pet_screen_datasource.dart';
import '../data/datasources/remote/activity_stats_datasource.dart';
import '../data/datasources/remote/friends_datasource.dart';
import '../data/models/pvp_models.dart';
import '../data/models/friends_response.dart';

abstract class PvpSignalRService {
  bool get isConnected;
  bool get isMatchRoomJoined;
  String? get hubUrl;
  String? get connectionId;

  Future<void> connect();
  Future<void> disconnect();
  Future<bool> joinMatch(String matchId);
  Future<void> leaveMatch(String matchId);
  void setEventHandlers({
    required void Function(Map<String, dynamic> event) onAssigned,
    required void Function(Map<String, dynamic> event) onProgress,
    required void Function(Map<String, dynamic> event) onFinished,
    required void Function(Map<String, dynamic> event) onSettling,
    required void Function(Map<String, dynamic> event) onCancelled,
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
  Future<void> Function()? _onReconnected;

  String _hubPath() => (configuredHubUrl?.isNotEmpty == true
      ? configuredHubUrl!
      : apiBaseUrl.replaceAll(RegExp(r'/*$'), '') + '/hubs/pvp-sprint');

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
        String? t;
        try {
          t = await accessTokenFactory!();
          _log('Token: length=${t.length}');
          final prefix = t.length > 10 ? t.substring(0, 10) : t;
          _log('Token prefix=$prefix');
        } catch (e) {
          _log('accessTokenFactory threw: $e');
        }

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
            final eq = (t != null && stored == t) ? 'MATCH' : 'DIFFER';
            _log('SharedPreferences token vs accessTokenFactory: $eq');
          }
        } catch (e) {
          _log('Failed to read SharedPreferences: $e');
        }
      }

      // Negotiate URL
      final negotiate =
          _hubPath().replaceAll(RegExp(r'/*$'), '') + '/negotiate';
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
            if (t == null) {
              throw Exception('accessTokenFactory returned null');
            }
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
          'match.finished',
          'match.settling',
          'match.cancelled',
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
    } else if (payload is Map) {
      data = Map<String, dynamic>.from(payload as Map);
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
      case 'match.finished':
        _onFinished?.call(data);
        break;
      case 'match.settling':
        _onSettling?.call(data);
        break;
      case 'match.cancelled':
        _onCancelled?.call(data);
        break;
      default:
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
  void setEventHandlers({
    required void Function(Map<String, dynamic> event) onAssigned,
    required void Function(Map<String, dynamic> event) onProgress,
    required void Function(Map<String, dynamic> event) onFinished,
    required void Function(Map<String, dynamic> event) onSettling,
    required void Function(Map<String, dynamic> event) onCancelled,
  }) {
    _onAssigned = onAssigned;
    _onProgress = onProgress;
    _onFinished = onFinished;
    _onSettling = onSettling;
    _onCancelled = onCancelled;
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
      case 'match.finished':
        _onFinished?.call(event);
        break;
      case 'match.settling':
        _onSettling?.call(event);
        break;
      case 'match.cancelled':
        _onCancelled?.call(event);
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

class PvpProvider extends ChangeNotifier {
  final PvpSprintDatasource _pvpDatasource;
  final PetScreenDatasource _petDatasource;
  final ActivityStatsDatasource _activityDatasource;
  final FriendsDatasource _friendsDatasource;
  final PvpSignalRService _signalRService;

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
  }) : _pvpDatasource = pvpDatasource ?? PvpSprintDatasource(apiClient),
       _petDatasource = petDatasource ?? PetScreenDatasource(apiClient),
       _activityDatasource =
           activityDatasource ?? ActivityStatsDatasource(apiClient: apiClient),
       _friendsDatasource =
           friendsDatasource ?? FriendsDatasource(apiClient ?? ApiClient()),
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
           );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasReceivedAssignedEvent = false;
  bool _hasMatchRoomJoined = false;
  String? _activeMatchId;
  DateTime? _matchmakingStartedAt;
  final Set<String> _processedEventIds = <String>{};
  final Map<String, int> _lastSequences = <String, int>{};

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

  PvpMatchmakingState _matchmakingState = PvpMatchmakingState.idle;
  PvpMatchmakingState get matchmakingState => _matchmakingState;

  PvpMatchResponse? _currentMatch;
  PvpMatchResponse? get currentMatch => _currentMatch;

  // Matchmaking trace
  String _lastMatchmakingStep = 'none';
  void _traceMatchmaking(String step) {
    _lastMatchmakingStep = step;
    _log(step);
  }

  PvpMatchResultResponse? _matchResult;
  PvpMatchResultResponse? get matchResult => _matchResult;

  String? _currentInviteId;
  String? get currentInviteId => _currentInviteId;

  String? get activeMatchId => _activeMatchId;

  String get currentOpponentName {
    for (final participant
        in _currentMatch?.participants ?? <PvpParticipantResponse>[]) {
      final name = participant.displayName?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return '';
  }

  Future<void> initializeSignalR() async {
    _signalRService.setEventHandlers(
      onAssigned: (event) => unawaited(handleSignalREvent(event)),
      onProgress: (event) => unawaited(handleSignalREvent(event)),
      onFinished: (event) => unawaited(handleSignalREvent(event)),
      onSettling: (event) => unawaited(handleSignalREvent(event)),
      onCancelled: (event) => unawaited(handleSignalREvent(event)),
    );

    // When SignalR reconnects, recover authoritative matchmaking state
    _signalRService.setReconnectedHandler(() async {
      _log('SignalR reconnected - recovering matchmaking status');
      await _recoverMatchmakingStateFromStatus();
    });

    // If using the default implementation, print debug info about token and negotiate URL
    try {
      if (_signalRService is DefaultPvpSignalRService) {
        await (_signalRService as DefaultPvpSignalRService)
            .debugLogAccessTokenAndNegotiateInfo();
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

  void _log(String message, {String? matchId}) {
    debugPrint(
      '[PvP][${DateTime.now().toIso8601String()}] $message${matchId != null ? ' matchId=$matchId' : ''}',
    );
  }

  void _updateState(PvpMatchmakingState state) {
    _matchmakingState = state;
    notifyListeners();
  }

  Future<void> _joinAndSyncMatch(String matchId) async {
    _activeMatchId = matchId;
    _log('GET Match', matchId: matchId);
    final matchResponse = await _pvpDatasource.getMatch(matchId);
    if (!matchResponse.success || matchResponse.data == null) {
      debugPrint('GET match failed after assigned: ${matchResponse.message}');
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final match = matchResponse.data!;
    _currentMatch = match;
    _lastSequences[matchId] = match.lastEventSequence ?? 0;

    final normalizedStatus = match.statusCode.toLowerCase();
    if (normalizedStatus == 'countdown') {
      _log('match.assigned -> countdown snapshot loaded', matchId: matchId);
    }
    if (normalizedStatus == 'countdown') {
      _updateState(PvpMatchmakingState.countdown);
      return;
    }

    if (normalizedStatus == 'running' || normalizedStatus == 'settling') {
      _updateState(PvpMatchmakingState.running);
      return;
    }

    _updateState(PvpMatchmakingState.waiting);
  }

  PvpMatchmakingState _mapStatusCodeToState(String statusCode) {
    switch (statusCode.toLowerCase()) {
      case 'countdown':
        return PvpMatchmakingState.countdown;
      case 'running':
      case 'settling':
        return PvpMatchmakingState.running;
      case 'waiting':
        return PvpMatchmakingState.waiting;
      default:
        return PvpMatchmakingState.idle;
    }
  }

  Future<void> _recoverMatchmakingStateFromStatus() async {
    _log('GET Matchmaking Status');
    final statusResponse = await _pvpDatasource.getMatchmakingStatus();
    if (!statusResponse.success || statusResponse.data == null) {
      _currentMatch = null;
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final status = statusResponse.data!;
    if (status.matchId != null && status.matchId!.isNotEmpty) {
      _log(
        'GET Matchmaking Status returned active match',
        matchId: status.matchId!,
      );

      final matchId = status.matchId!;
      final normalized = status.statusCode.toLowerCase();
      if (normalized == 'countdown') {
        _log('Recovery detected countdown', matchId: matchId);
        try {
          _log('Joining room...', matchId: matchId);
          final joined = await _signalRService.joinMatch(matchId);
          _log('JoinMatch ${joined ? 'success' : 'failed'}', matchId: matchId);
          if (!joined) {
            _log(
              'Recovery: JoinMatch failed, aborting recovery',
              matchId: matchId,
            );
            // fall back to syncing via GET only
            await _joinAndSyncMatch(matchId);
            return;
          }

          _log('Fetching match snapshot...', matchId: matchId);
          await _joinAndSyncMatch(matchId);
          _log('Snapshot loaded', matchId: matchId);
          if (_matchmakingState == PvpMatchmakingState.countdown) {
            _log('State changed to countdown', matchId: matchId);
          }
          _log('notifyListeners()', matchId: matchId);
          notifyListeners();
          _log('UI navigation triggered', matchId: matchId);
          return;
        } catch (e, st) {
          _log('Recovery failed: $e');
          debugPrint('$e\n$st');
          // fallback to normal joinAndSync to try to recover
          try {
            await _joinAndSyncMatch(matchId);
          } catch (e2) {
            _log('Recovery fallback failed: $e2', matchId: matchId);
          }
          return;
        }
      }

      // If not countdown, still join and sync to be safe
      await _joinAndSyncMatch(matchId);
      return;
    }

    final nextState = _mapStatusCodeToState(status.statusCode);
    if (nextState == PvpMatchmakingState.idle) {
      _currentMatch = null;
    }
    _updateState(nextState);
  }

  Future<void> handleSignalREvent(Map<String, dynamic> event) async {
    final eventType = event['eventType']?.toString() ?? 'unknown';
    final eventId = event['eventId']?.toString();
    final payload =
        event['payload'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final matchId =
        payload['matchId']?.toString() ?? event['aggregateId']?.toString();

    // dedupe
    if (eventId != null && _processedEventIds.contains(eventId)) {
      _log('SignalR duplicate event ignored', matchId: matchId);
      _traceMatchmaking('stopped at: duplicate event');
      return;
    }

    if (eventId != null) {
      _processedEventIds.add(eventId);
    }

    // Log reception and payload
    _log('SignalR Event: $eventType', matchId: matchId);
    _log('Exact payload: $event');
    final receivedMethod = event['_receivedMethod']?.toString();
    if (receivedMethod != null) {
      _log('SignalR method received: $receivedMethod');
      _traceMatchmaking('[6] SignalR event received ($receivedMethod)');
    } else {
      _traceMatchmaking('[6] SignalR event received (method unknown)');
    }
    _traceMatchmaking('[7] Event payload');

    // Handle specific events
    if (eventType == 'match.assigned') {
      _hasReceivedAssignedEvent = true;
      if (matchId != null && matchId.isNotEmpty) {
        _activeMatchId = matchId;
        _log('match.assigned', matchId: matchId);

        _traceMatchmaking('[8] JoinMatch invoked');
        _log('Invoking JoinMatch for matchId=$matchId');
        final joined = await _signalRService.joinMatch(matchId);
        _log('[9] JoinMatch completed: success=$joined');
        _hasMatchRoomJoined = joined;

        if (!joined) {
          _traceMatchmaking('stopped at: JoinMatch failed');
          _log('JoinMatch failed', matchId: matchId);
          return;
        }

        _log('SignalR room verified', matchId: matchId);
        _traceMatchmaking('[10] GET /matches/$matchId');
        await _joinAndSyncMatch(matchId);

        // after sync, report snapshot and state
        _traceMatchmaking('[11] Match snapshot loaded');
        if (_matchmakingState == PvpMatchmakingState.countdown) {
          _traceMatchmaking('[12] Countdown entered');
          _log('Entered Countdown', matchId: matchId);
        } else if (_matchmakingState == PvpMatchmakingState.running) {
          _traceMatchmaking('[13] Running entered');
          _log('Entered Running', matchId: matchId);
        }
      } else {
        _log('match.assigned without matchId');
        _traceMatchmaking('stopped at: assigned without matchId');
      }
      return;
    }

    if (eventType == 'match.progress') {
      _log('match.progress', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
        _traceMatchmaking('handled match.progress');
      }
      return;
    }

    if (eventType == 'match.finished') {
      _log('match.finished', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
      }
      _updateState(PvpMatchmakingState.finished);
      _traceMatchmaking('handled match.finished');
      return;
    }

    if (eventType == 'match.settling') {
      _log('match.settling', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
      }
      _updateState(PvpMatchmakingState.running);
      _traceMatchmaking('handled match.settling');
      return;
    }

    if (eventType == 'match.cancelled') {
      _log('match.cancelled', matchId: matchId);
      if (matchId != null && matchId.isNotEmpty) {
        await _joinAndSyncMatch(matchId);
      }
      _updateState(PvpMatchmakingState.cancelled);
      _traceMatchmaking('handled match.cancelled');
      return;
    }
  }

  Future<void> _verifyBotFallbackTimer() async {
    if (_matchmakingStartedAt == null) {
      return;
    }

    await Future.delayed(const Duration(seconds: 20));
    if (_matchmakingState == PvpMatchmakingState.waiting) {
      _log(
        'Bot fallback check: still waiting after 20s (roomJoined=$_hasMatchRoomJoined)',
      );
      _log('Last matchmaking step: $_lastMatchmakingStep');
      if (!_hasReceivedAssignedEvent) {
        _log('Bot fallback check: no match.assigned received');
      }
      final statusResponse = await _pvpDatasource.getMatchmakingStatus();
      if (statusResponse.success && statusResponse.data != null) {
        final status = statusResponse.data!;
        _log(
          "Bot fallback check: matchmaking status=${status.statusCode}, matchId=${status.matchId ?? 'null'}",
          matchId: status.matchId,
        );
      }
    }
  }

  Future<void> sendInvite(String targetUserId) async {
    _currentInviteId = null;
    _updateState(PvpMatchmakingState.invitePending);

    final response = await _pvpDatasource.createInvite(targetUserId);
    if (!response.success || response.data == null) {
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    _currentInviteId = response.data!.inviteId;
    notifyListeners();
  }

  Future<void> respondToInvite(String inviteId, {required bool accept}) async {
    final response = await _pvpDatasource.respondToInvite(
      inviteId,
      accept: accept,
    );
    if (!response.success || response.data == null) {
      return;
    }

    if (accept &&
        response.data!.matchId != null &&
        response.data!.matchId!.isNotEmpty) {
      await syncMatch(response.data!.matchId!);
      return;
    }

    _currentInviteId = null;
    _updateState(PvpMatchmakingState.idle);
  }

  Future<void> cancelInvite(String inviteId) async {
    final response = await _pvpDatasource.cancelInvite(inviteId);
    if (response.success) {
      _currentInviteId = null;
      _updateState(PvpMatchmakingState.idle);
    }
  }

  Future<void> syncMatch(String matchId) async {
    final response = await _pvpDatasource.getMatch(matchId);
    if (!response.success || response.data == null) {
      return;
    }

    _currentMatch = response.data!;
    final normalizedStatus = response.data!.statusCode.toLowerCase();
    if (normalizedStatus == 'countdown') {
      _updateState(PvpMatchmakingState.countdown);
      return;
    }

    if (normalizedStatus == 'running' || normalizedStatus == 'settling') {
      _updateState(PvpMatchmakingState.running);
      return;
    }

    if (normalizedStatus == 'finished') {
      _updateState(PvpMatchmakingState.finished);
      return;
    }

    if (normalizedStatus == 'cancelled') {
      _updateState(PvpMatchmakingState.cancelled);
      return;
    }

    _updateState(PvpMatchmakingState.waiting);
  }

  Future<void> loadMatchResult(String matchId) async {
    final response = await _pvpDatasource.getMatchResult(matchId);
    if (!response.success || response.data == null) {
      return;
    }

    _matchResult = response.data!;
    notifyListeners();
  }

  Future<void> claimMatchReward(String matchId) async {
    final response = await _pvpDatasource.claimMatchReward(matchId);
    if (!response.success || response.data == null) {
      return;
    }

    await loadMatchResult(matchId);
  }

  Future<void> startMatchmaking() async {
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
        _log('SignalR initialization failed before matchmaking: $e');
        debugPrint(st.toString());
        // Do not continue matchmaking if SignalR failed to initialize
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

    if (_matchmakingState == PvpMatchmakingState.waiting ||
        _matchmakingState == PvpMatchmakingState.countdown ||
        _matchmakingState == PvpMatchmakingState.running) {
      return;
    }

    _updateState(PvpMatchmakingState.connecting);
    _traceMatchmaking('[3] POST /matchmaking');

    final response = await _pvpDatasource.startMatchmaking();
    _traceMatchmaking('[4] Response from POST /matchmaking');
    _log(
      'POST /matchmaking response: status=${response.status}, success=${response.success}, message=${response.message}',
    );
    if (!response.success) {
      if (response.status == 409) {
        await _recoverMatchmakingStateFromStatus();
        return;
      }

      debugPrint('Matchmaking failed: ${response.message}');
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    if (response.data == null) {
      _updateState(PvpMatchmakingState.idle);
      return;
    }

    final match = response.data!;
    _currentMatch = match;

    final normalizedStatus = match.statusCode.toLowerCase();
    if (normalizedStatus == 'waiting' || match.matchId.isEmpty) {
      _updateState(PvpMatchmakingState.waiting);
      _traceMatchmaking('[5] Waiting state entered');
      unawaited(_verifyBotFallbackTimer());
      return;
    }

    await _joinAndSyncMatch(match.matchId);
  }

  Future<void> cancelMatchmaking() async {
    _log('DELETE Matchmaking');
    if (_matchmakingState != PvpMatchmakingState.waiting) {
      return;
    }

    final response = await _pvpDatasource.cancelMatchmaking();
    if (response.success) {
      _currentMatch = null;
      _updateState(PvpMatchmakingState.idle);
      if (_activeMatchId != null) {
        unawaited(_signalRService.leaveMatch(_activeMatchId!));
      }
      return;
    }

    if (response.status == 404 || response.status == 409) {
      await _recoverMatchmakingStateFromStatus();
      return;
    }

    _currentMatch = null;
    _updateState(PvpMatchmakingState.idle);
  }

  void acceptChallenge(String inviteId) {
    respondToInvite(inviteId, accept: true);
  }

  void rejectChallenge(String inviteId) {
    respondToInvite(inviteId, accept: false);
  }
}
