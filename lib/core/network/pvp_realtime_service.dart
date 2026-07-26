import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

typedef PvpRealtimeEventHandler = void Function(Map<String, dynamic> payload);

class PvpRealtimeService {
  PvpRealtimeService(this.apiBaseUrl, this.getAccessToken);

  final String apiBaseUrl;
  final Future<String> Function() getAccessToken;

  HubConnection? _connection;
  final Map<String, List<PvpRealtimeEventHandler>> _handlers = {};

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    final options = HttpConnectionOptions(
      accessTokenFactory: () async {
        final token = await getAccessToken();
        return token;
      },
    );

    final connection = HubConnectionBuilder()
        .withUrl('$apiBaseUrl/hubs/pvp-sprint', options: options)
        .withAutomaticReconnect(retryDelays: <int>[0, 2000, 5000, 10000, 30000])
        .build();

    connection.onclose(({error}) {
      _connection = connection;
    });

    for (final entry in _handlers.entries) {
      final eventName = entry.key;
      connection.on(eventName, (arguments) {
        if (arguments == null || arguments.isEmpty) {
          return;
        }

        final raw = arguments.first;
        if (raw is! Map) {
          return;
        }

        final payload = Map<String, dynamic>.from(raw);
        for (final registered in _handlers[eventName] ?? []) {
          registered(payload);
        }
      });
    }

    _connection = connection;
    await _connection!.start();
  }

  void on(String eventName, PvpRealtimeEventHandler handler) {
    final handlers = _handlers[eventName] ?? <PvpRealtimeEventHandler>[];
    handlers.add(handler);
    _handlers[eventName] = handlers;

    _connection?.on(eventName, (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final raw = arguments.first;
      if (raw is! Map) {
        return;
      }

      final payload = Map<String, dynamic>.from(raw);
      for (final registered in _handlers[eventName] ?? []) {
        registered(payload);
      }
    });
  }

  Future<void> joinMatch(String matchId) async {
    if (_connection?.state != HubConnectionState.Connected) {
      throw StateError('SignalR is not connected');
    }
    await _connection!.invoke('JoinMatch', args: <Object>[matchId]);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}
