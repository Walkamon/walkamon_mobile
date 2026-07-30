import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/token_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/network/presence_realtime_service.dart';
import '../data/models/friends_response.dart';

class PresenceSnapshot {
  const PresenceSnapshot({
    required this.userId,
    required this.isOnline,
    required this.pvpAvailabilityCode,
  });

  final String userId;
  final bool isOnline;
  final String pvpAvailabilityCode;
}

class PresenceProvider extends ChangeNotifier with WidgetsBindingObserver {
  PresenceProvider({PresenceRealtimeClient? client})
    : _client =
          client ??
          SignalRPresenceRealtimeClient(
            hubUrl:
                '${ApiConstants.baseUrl.replaceAll(RegExp(r'/*$'), '')}/hubs/presence',
            accessTokenFactory: _readAccessToken,
          ) {
    WidgetsBinding.instance.addObserver(this);
    _statusSubscription = _client.statusChanges.listen(_handleStatusChanged);
    _eventSubscription = _client.events.listen(_handleEvent);
  }

  static const _maxRememberedEventIds = 1000;

  final PresenceRealtimeClient _client;
  final _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, PresenceSnapshot> _presenceByUserId = {};
  final Set<String> _processedEventIds = <String>{};
  final Queue<String> _processedEventOrder = Queue<String>();

  StreamSubscription<PresenceConnectionStatus>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  Timer? _retryTimer;
  bool _authenticated = false;
  bool _disposed = false;
  int _connectionGeneration = 0;
  Map<String, dynamic>? _latestMatchAssignedEvent;

  PresenceConnectionStatus get connectionStatus => _client.status;
  bool get isConnected =>
      connectionStatus == PresenceConnectionStatus.connected;
  int get connectionGeneration => _connectionGeneration;
  Stream<Map<String, dynamic>> get events => _eventStreamController.stream;
  Map<String, dynamic>? get latestMatchAssignedEvent =>
      _latestMatchAssignedEvent == null
      ? null
      : Map<String, dynamic>.from(_latestMatchAssignedEvent!);

  void clearLatestMatchAssignedEvent(String? eventId) {
    final latest = _latestMatchAssignedEvent;
    if (latest == null) return;
    final latestEventId = latest['eventId']?.toString();
    if (eventId == null || latestEventId == null || latestEventId == eventId) {
      _latestMatchAssignedEvent = null;
    }
  }

  PresenceSnapshot? presenceFor(String userId) => _presenceByUserId[userId];

  FriendsResponse applyPresence(FriendsResponse friend) {
    final snapshot = presenceFor(friend.userId);
    if (snapshot == null) return friend;
    return friend.copyWithPresence(
      isOnline: snapshot.isOnline,
      pvpAvailabilityCode: snapshot.pvpAvailabilityCode,
    );
  }

  Future<void> synchronizeAuthentication(bool authenticated) async {
    if (_disposed) return;
    final changed = _authenticated != authenticated;
    _authenticated = authenticated;

    if (!authenticated) {
      _retryTimer?.cancel();
      _retryTimer = null;
      if (changed || _client.status != PresenceConnectionStatus.disconnected) {
        await _client.disconnect();
      }
      _presenceByUserId.clear();
      _latestMatchAssignedEvent = null;
      _clearDedupe();
      if (!_disposed) notifyListeners();
      return;
    }

    await ensureConnected();
  }

  Future<void> ensureConnected() async {
    if (_disposed || !_authenticated) return;
    try {
      await _client.connect();
    } catch (error, stackTrace) {
      debugPrint('[Presence] connect failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> disconnect() async {
    _authenticated = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _client.disconnect();
    _presenceByUserId.clear();
    _latestMatchAssignedEvent = null;
    _clearDedupe();
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ensureConnected());
    }
    // Do not stop the connection on inactive/paused. Android may keep the
    // process alive, and SignalR automatic reconnect handles network changes.
  }

  void _handleStatusChanged(PresenceConnectionStatus status) {
    if (_disposed) return;
    debugPrint('[Presence] status=${status.name}');
    if (status == PresenceConnectionStatus.connected) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _connectionGeneration++;
    } else if (status == PresenceConnectionStatus.disconnected) {
      _scheduleReconnect();
    }
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_disposed || !_authenticated || _retryTimer?.isActive == true) {
      return;
    }
    _retryTimer = Timer(const Duration(seconds: 10), () {
      _retryTimer = null;
      unawaited(ensureConnected());
    });
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (_disposed || !_rememberEvent(event['eventId']?.toString())) return;

    final eventType =
        event['eventType']?.toString() ??
        event['_receivedMethod']?.toString() ??
        '';
    debugPrint(
      '[Presence] event=$eventType eventId=${event['eventId'] ?? 'none'}',
    );
    if (eventType == 'presence.changed') {
      _applyPresenceEvent(event);
    } else if (eventType == 'match.assigned') {
      _latestMatchAssignedEvent = Map<String, dynamic>.from(event);
    }

    _eventStreamController.add(Map<String, dynamic>.from(event));
    notifyListeners();
  }

  void _applyPresenceEvent(Map<String, dynamic> event) {
    final rawPayload = event['payload'];
    final payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : event;
    final userId =
        payload['userId']?.toString() ?? event['aggregateId']?.toString();
    if (userId == null || userId.isEmpty) return;

    final isOnline = payload['isOnline'] == true;
    final availability =
        payload['pvpAvailabilityCode']?.toString() ??
        (isOnline ? 'available' : 'offline');
    _presenceByUserId[userId] = PresenceSnapshot(
      userId: userId,
      isOnline: isOnline,
      pvpAvailabilityCode: availability,
    );
  }

  bool _rememberEvent(String? eventId) {
    if (eventId == null || eventId.isEmpty) return true;
    if (!_processedEventIds.add(eventId)) return false;

    _processedEventOrder.addLast(eventId);
    while (_processedEventOrder.length > _maxRememberedEventIds) {
      _processedEventIds.remove(_processedEventOrder.removeFirst());
    }
    return true;
  }

  void _clearDedupe() {
    _processedEventIds.clear();
    _processedEventOrder.clear();
  }

  static Future<String> _readAccessToken() async {
    final inMemory = TokenStorage.token;
    if (inMemory != null && inMemory.isNotEmpty) return inMemory;

    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString('access_token');
    if (stored != null && stored.isNotEmpty) {
      TokenStorage.setToken(stored);
      return stored;
    }
    throw StateError('No access token is available for PresenceHub.');
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    unawaited(_statusSubscription?.cancel());
    unawaited(_eventSubscription?.cancel());
    unawaited(_client.disconnect());
    unawaited(_eventStreamController.close());
    super.dispose();
  }
}
