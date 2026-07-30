import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/core/network/presence_realtime_service.dart';
import 'package:walkamon_mobile/data/datasources/remote/pvp_sprint_datasource.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/providers/presence_provider.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';

class _FakePvpSprintDatasource extends PvpSprintDatasource {
  final List<String> fetchedMatchIds = [];

  @override
  Future<ApiResponse<PvpMatchResponse>> getMatch(String matchId) async {
    fetchedMatchIds.add(matchId);
    return ApiResponse<PvpMatchResponse>(
      success: true,
      status: 200,
      message: 'ok',
      data: PvpMatchResponse(
        matchId: matchId,
        matchTypeCode: 'ranked',
        statusCode: 'countdown',
        participants: [],
      ),
    );
  }
}

class _FakeSignalRService implements PvpSignalRService {
  final List<String> joinedMatchIds = [];

  @override
  bool get isConnected => true;

  @override
  bool get isMatchRoomJoined => joinedMatchIds.isNotEmpty;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> joinMatch(String matchId) async {
    joinedMatchIds.add(matchId);
    return true;
  }

  @override
  Future<void> leaveMatch(String matchId) async {}

  @override
  Future<Map<String, dynamic>> readyMatch(String matchId) async {
    return {
      'matchId': matchId,
      'allReady': true,
      'countdownStartsAt': '2026-07-27T03:00:00Z',
      'countdownEndsAt': '2026-07-27T03:00:05Z',
      'serverTime': '2026-07-27T03:00:00Z',
    };
  }

  @override
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
  }) {}

  @override
  Future<void> emitEvent(Map<String, dynamic> event) async {
    // No-op for fake service; tests call provider.handleSignalREvent directly.
  }

  @override
  void setReconnectedHandler(Future<void> Function()? onReconnected) {
    // No-op for fake service
  }

  @override
  String? get hubUrl => null;

  @override
  String? get connectionId => 'fake-conn';
}

class _FakePresenceRealtimeClient implements PresenceRealtimeClient {
  final _statusController =
      StreamController<PresenceConnectionStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  var _status = PresenceConnectionStatus.disconnected;

  @override
  PresenceConnectionStatus get status => _status;

  @override
  Stream<PresenceConnectionStatus> get statusChanges =>
      _statusController.stream;

  @override
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  @override
  Future<void> connect() async {
    _status = PresenceConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _status = PresenceConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  void emit(Map<String, dynamic> event) => _eventController.add(event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveCountdownPhase keeps a pre-start countdown alive', () {
    final now = DateTime.utc(2026, 7, 27, 3, 0, 29);
    final startsAt = DateTime.utc(2026, 7, 27, 3, 0, 33);
    final endsAt = DateTime.utc(2026, 7, 27, 3, 0, 38);

    final phase = resolveCountdownPhase(
      countdownActive: true,
      countdownStartsAt: startsAt,
      countdownEndsAt: endsAt,
      serverNow: now,
    );

    expect(phase, PvpCountdownPhase.beforeStart);
  });

  test(
    'assigned event refreshes match snapshot and moves to countdown',
    () async {
      final datasource = _FakePvpSprintDatasource();
      final signalRService = _FakeSignalRService();
      final provider = PvpProvider(
        pvpDatasource: datasource,
        signalRService: signalRService,
      );

      await provider.handleSignalREvent({
        'eventType': 'match.assigned',
        'payload': {
          'matchId': 'match-1',
          'statusCode': 'countdown',
          'serverTime': '2026-07-27T03:00:00Z',
        },
      });

      expect(provider.matchmakingState, PvpMatchmakingState.countdown);
      expect(provider.currentMatch?.matchId, 'match-1');
      expect(datasource.fetchedMatchIds, contains('match-1'));
      expect(signalRService.joinedMatchIds, contains('match-1'));
    },
  );

  test(
    'PresenceHub assignment connects SprintHub and is deduped across hubs',
    () async {
      final datasource = _FakePvpSprintDatasource();
      final signalRService = _FakeSignalRService();
      final presenceClient = _FakePresenceRealtimeClient();
      final presenceProvider = PresenceProvider(client: presenceClient);
      await presenceProvider.synchronizeAuthentication(true);
      final provider = PvpProvider(
        pvpDatasource: datasource,
        signalRService: signalRService,
        presenceProvider: presenceProvider,
      );
      final event = <String, dynamic>{
        'eventId': 'assigned-event-1',
        'eventType': 'match.assigned',
        'payload': <String, dynamic>{
          'matchId': 'match-presence-1',
          'statusCode': 'countdown',
          'serverTime': '2026-07-27T03:00:00Z',
        },
      };

      presenceClient.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await provider.handleSignalREvent(event);

      expect(signalRService.joinedMatchIds, ['match-presence-1']);
      expect(datasource.fetchedMatchIds, ['match-presence-1']);
      expect(provider.matchmakingState, PvpMatchmakingState.countdown);
      expect(presenceProvider.latestMatchAssignedEvent, isNull);

      provider.dispose();
      presenceProvider.dispose();
    },
  );
}
