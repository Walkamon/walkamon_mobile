import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/presence_realtime_service.dart';
import 'package:walkamon_mobile/data/models/friends_response.dart';
import 'package:walkamon_mobile/providers/presence_provider.dart';

class _FakePresenceRealtimeClient implements PresenceRealtimeClient {
  final _statusController =
      StreamController<PresenceConnectionStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  var _status = PresenceConnectionStatus.disconnected;
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  PresenceConnectionStatus get status => _status;

  @override
  Stream<PresenceConnectionStatus> get statusChanges =>
      _statusController.stream;

  @override
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
    setStatus(PresenceConnectionStatus.connecting);
    setStatus(PresenceConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    setStatus(PresenceConnectionStatus.disconnected);
  }

  void setStatus(PresenceConnectionStatus value) {
    _status = value;
    _statusController.add(value);
  }

  void emit(Map<String, dynamic> event) {
    _eventController.add(event);
  }
}

Future<void> _flushEvents() =>
    Future<void>.delayed(const Duration(milliseconds: 1));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connects after authentication and disconnects on logout', () async {
    final client = _FakePresenceRealtimeClient();
    final provider = PresenceProvider(client: client);

    await provider.synchronizeAuthentication(true);
    await _flushEvents();

    expect(client.connectCalls, 1);
    expect(provider.isConnected, isTrue);

    await provider.synchronizeAuthentication(false);
    await _flushEvents();

    expect(client.disconnectCalls, 1);
    expect(provider.isConnected, isFalse);
    provider.dispose();
  });

  test('applies presence.changed and dedupes the same eventId', () async {
    final client = _FakePresenceRealtimeClient();
    final provider = PresenceProvider(client: client);
    var forwardedEvents = 0;
    final subscription = provider.events.listen((_) => forwardedEvents++);

    await provider.synchronizeAuthentication(true);
    final event = <String, dynamic>{
      'eventId': 'presence-1',
      'eventType': 'presence.changed',
      'aggregateId': 'friend-1',
      'payload': <String, dynamic>{
        'userId': 'friend-1',
        'isOnline': true,
        'pvpAvailabilityCode': 'available',
      },
    };
    client.emit(event);
    client.emit(event);
    await _flushEvents();

    final friend = provider.applyPresence(
      FriendsResponse(
        userId: 'friend-1',
        username: 'Friend',
        email: 'friend@example.com',
      ),
    );
    expect(friend.isOnline, isTrue);
    expect(friend.pvpAvailabilityCode, 'available');
    expect(forwardedEvents, 1);

    await subscription.cancel();
    provider.dispose();
  });

  test('resume reconnects after the socket becomes disconnected', () async {
    final client = _FakePresenceRealtimeClient();
    final provider = PresenceProvider(client: client);
    await provider.synchronizeAuthentication(true);
    await _flushEvents();

    client.setStatus(PresenceConnectionStatus.disconnected);
    await _flushEvents();
    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(client.connectCalls, 1);

    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _flushEvents();
    expect(client.connectCalls, 2);
    expect(provider.isConnected, isTrue);

    provider.dispose();
  });

  test('stores the latest match assignment for a later PvP screen', () async {
    final client = _FakePresenceRealtimeClient();
    final provider = PresenceProvider(client: client);
    await provider.synchronizeAuthentication(true);

    client.emit(<String, dynamic>{
      'eventId': 'assigned-1',
      'eventType': 'match.assigned',
      'payload': <String, dynamic>{'matchId': 'match-1'},
    });
    await _flushEvents();

    expect(provider.latestMatchAssignedEvent?['eventId'], 'assigned-1');
    provider.clearLatestMatchAssignedEvent('assigned-1');
    expect(provider.latestMatchAssignedEvent, isNull);

    provider.dispose();
  });
}
