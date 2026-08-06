import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

enum PresenceConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

abstract class PresenceRealtimeClient {
  PresenceConnectionStatus get status;
  Stream<PresenceConnectionStatus> get statusChanges;
  Stream<Map<String, dynamic>> get events;

  Future<void> connect();
  Future<void> disconnect();
}

class SignalRPresenceRealtimeClient implements PresenceRealtimeClient {
  SignalRPresenceRealtimeClient({
    required this.hubUrl,
    required this.accessTokenFactory,
  });

  static const eventNames = <String>[
    'presence.changed',
    'invite.created',
    'invite.declined',
    'invite.cancelled',
    'invite.expired',
    'match.assigned',
    'match.forfeited',
    'match.finished',
    'match.cancelled',
    'queue.failed',
  ];

  final String hubUrl;
  final Future<String> Function() accessTokenFactory;

  final _statusController =
      StreamController<PresenceConnectionStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  HubConnection? _connection;
  Future<void>? _connectFuture;
  var _generation = 0;
  var _status = PresenceConnectionStatus.disconnected;

  @override
  PresenceConnectionStatus get status => _status;

  @override
  Stream<PresenceConnectionStatus> get statusChanges =>
      _statusController.stream;

  @override
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  @override
  Future<void> connect() {
    if (_status == PresenceConnectionStatus.connected ||
        _status == PresenceConnectionStatus.reconnecting) {
      return Future<void>.value();
    }

    final current = _connectFuture;
    if (current != null) return current;

    final future = _startConnection();
    _connectFuture = future;
    return future.whenComplete(() {
      if (identical(_connectFuture, future)) {
        _connectFuture = null;
      }
    });
  }

  Future<void> _startConnection() async {
    final generation = ++_generation;
    _setStatus(PresenceConnectionStatus.connecting);

    final options = HttpConnectionOptions(
      accessTokenFactory: () async {
        final token = await accessTokenFactory();
        if (token.trim().isEmpty) {
          throw StateError('PresenceHub access token is empty.');
        }
        return token;
      },
    );

    final connection = HubConnectionBuilder()
        .withUrl(hubUrl, options: options)
        .withAutomaticReconnect(retryDelays: <int>[0, 2000, 5000, 10000, 30000])
        .build();

    for (final eventName in eventNames) {
      connection.on(
        eventName,
        (arguments) => _handleEvent(eventName, arguments),
      );
    }

    connection.onreconnecting(({error}) {
      if (!identical(_connection, connection)) return;
      _setStatus(PresenceConnectionStatus.reconnecting);
    });

    connection.onreconnected(({connectionId}) {
      if (!identical(_connection, connection)) return;
      _setStatus(PresenceConnectionStatus.connected);
    });

    connection.onclose(({error}) {
      if (!identical(_connection, connection)) return;
      _connection = null;
      _setStatus(PresenceConnectionStatus.disconnected);
    });

    _connection = connection;
    try {
      await connection.start();
      if (generation != _generation || !identical(_connection, connection)) {
        await connection.stop();
        return;
      }
      _setStatus(PresenceConnectionStatus.connected);
    } catch (_) {
      if (identical(_connection, connection)) {
        _connection = null;
        _setStatus(PresenceConnectionStatus.disconnected);
      }
      rethrow;
    }
  }

  void _handleEvent(String methodName, List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final raw = arguments.first;

    Map<String, dynamic>? event;
    if (raw is Map<String, dynamic>) {
      event = Map<String, dynamic>.from(raw);
    } else if (raw is Map) {
      event = Map<String, dynamic>.from(raw);
    }
    if (event == null) return;

    event['_receivedMethod'] = methodName;
    _eventController.add(event);
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _connectFuture = null;
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      await connection.stop();
    }
    _setStatus(PresenceConnectionStatus.disconnected);
  }

  void _setStatus(PresenceConnectionStatus value) {
    if (_status == value) return;
    _status = value;
    _statusController.add(value);
  }
}
