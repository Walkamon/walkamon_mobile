import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/pvp_sprint_datasource.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';

class _FakePvpSignalRService implements PvpSignalRService {
  bool joinResult = true;
  int joinCount = 0;
  int readyCount = 0;

  @override
  bool get isConnected => true;

  @override
  bool get isMatchRoomJoined => false;

  @override
  String? get hubUrl => null;

  @override
  String? get connectionId => 'fake-connection';

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> joinMatch(String matchId) async {
    joinCount++;
    return joinResult;
  }

  @override
  Future<void> leaveMatch(String matchId) async {}

  @override
  Future<Map<String, dynamic>> readyMatch(String matchId) async {
    readyCount++;
    return {'matchId': matchId, 'allReady': false};
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
    void Function(Map<String, dynamic> event)? onQueueFailed,
  }) {}

  @override
  void setReconnectedHandler(Future<void> Function()? onReconnected) {}

  @override
  Future<void> emitEvent(Map<String, dynamic> event) async {}
}

class _FakePvpSprintDatasource extends PvpSprintDatasource {
  int statusCallCount = 0;
  String? createdInviteId;

  @override
  Future<ApiResponse<PvpMatchResponse>> startMatchmaking() async {
    return ApiResponse<PvpMatchResponse>(
      success: false,
      status: 409,
      message: 'conflict',
    );
  }

  @override
  Future<ApiResponse<PvpMatchmakingStatusResponse>>
  getMatchmakingStatus() async {
    statusCallCount++;
    return ApiResponse<PvpMatchmakingStatusResponse>(
      success: true,
      status: 200,
      message: 'ok',
      data: PvpMatchmakingStatusResponse(
        activityType: 'queue_waiting',
        statusCode: 'waiting',
        matchId: null,
      ),
    );
  }

  @override
  Future<ApiResponse<PvpInviteResponse>> createInvite(
    String targetUserId,
  ) async {
    createdInviteId = 'invite-$targetUserId';
    return ApiResponse<PvpInviteResponse>(
      success: true,
      status: 200,
      message: 'invite created',
      data: PvpInviteResponse(
        inviteId: createdInviteId!,
        user: PvpUserResponse(userId: 'friend-id', username: 'Friend'),
        statusCode: 'pending',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      ),
    );
  }
}

class _RecoveringPvpSprintDatasource extends PvpSprintDatasource {
  int statusCallCount = 0;

  @override
  Future<ApiResponse<PvpMatchResponse>> startMatchmaking() async {
    return ApiResponse<PvpMatchResponse>(
      success: true,
      status: 200,
      message: 'queued',
      data: PvpMatchResponse(
        matchId: '',
        matchTypeCode: 'ranked',
        statusCode: 'waiting',
        participants: const [],
      ),
    );
  }

  @override
  Future<ApiResponse<PvpMatchmakingStatusResponse>>
  getMatchmakingStatus() async {
    statusCallCount++;
    return ApiResponse<PvpMatchmakingStatusResponse>(
      success: true,
      status: 200,
      message: 'assigned',
      data: PvpMatchmakingStatusResponse(
        activityType: 'pvp_sprint',
        statusCode: 'countdown',
        matchId: 'match-recovered',
      ),
    );
  }

  @override
  Future<ApiResponse<PvpMatchResponse>> getMatch(String matchId) async {
    final startsAt = DateTime.now().toUtc();
    final endsAt = startsAt.add(const Duration(seconds: 5));
    return ApiResponse<PvpMatchResponse>(
      success: true,
      status: 200,
      message: 'match',
      data: PvpMatchResponse(
        matchId: matchId,
        matchTypeCode: 'ranked',
        statusCode: 'countdown',
        countdownStartsAt: startsAt,
        countdownEndsAt: endsAt,
        serverTime: startsAt,
        participants: const [],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PvpProvider', () {
    test('sendInvite marks the provider as invite pending', () async {
      final datasource = _FakePvpSprintDatasource();
      final provider = PvpProvider(pvpDatasource: datasource);

      await provider.sendInvite('friend-id');

      expect(provider.matchmakingState, PvpMatchmakingState.invitePending);
      expect(provider.currentInviteId, 'invite-friend-id');
    });

    test(
      'startMatchmaking recovers from 409 using matchmaking status',
      () async {
        final datasource = _FakePvpSprintDatasource();
        final provider = PvpProvider(
          pvpDatasource: datasource,
          signalRService: _FakePvpSignalRService(),
        );

        await provider.startMatchmaking();

        expect(provider.matchmakingState, PvpMatchmakingState.waiting);
        expect(datasource.statusCallCount, 1);
        provider.dispose();
      },
    );

    test(
      'polls status after the recovery delay when match.assigned is missed',
      () async {
        final datasource = _RecoveringPvpSprintDatasource();
        final signalR = _FakePvpSignalRService();
        final provider = PvpProvider(
          pvpDatasource: datasource,
          signalRService: signalR,
          matchmakingRecoveryDelay: const Duration(milliseconds: 10),
          matchmakingRecoveryInterval: const Duration(milliseconds: 5),
        );

        await provider.startMatchmaking();
        expect(provider.matchmakingState, PvpMatchmakingState.waiting);

        await Future<void>.delayed(const Duration(milliseconds: 35));

        expect(datasource.statusCallCount, greaterThanOrEqualTo(1));
        expect(signalR.joinCount, greaterThanOrEqualTo(1));
        expect(provider.matchmakingState, PvpMatchmakingState.countdown);
        provider.dispose();
      },
    );

    test('cancel stops a pending recovery timer', () async {
      final datasource = _RecoveringPvpSprintDatasource();
      final provider = PvpProvider(
        pvpDatasource: datasource,
        signalRService: _FakePvpSignalRService(),
        matchmakingRecoveryDelay: const Duration(milliseconds: 20),
        matchmakingRecoveryInterval: const Duration(milliseconds: 5),
      );

      await provider.startMatchmaking();
      await provider.cancelMatchmaking();
      await Future<void>.delayed(const Duration(milliseconds: 35));

      expect(datasource.statusCallCount, 0);
      expect(provider.matchmakingState, PvpMatchmakingState.idle);
      provider.dispose();
    });

    test('queue.failed exits waiting immediately', () async {
      final datasource = _FakePvpSprintDatasource();
      final provider = PvpProvider(
        pvpDatasource: datasource,
        signalRService: _FakePvpSignalRService(),
        matchmakingRecoveryDelay: const Duration(milliseconds: 20),
      );

      await provider.startMatchmaking();
      expect(provider.matchmakingState, PvpMatchmakingState.waiting);

      await provider.handleSignalREvent({
        'eventType': 'queue.failed',
        'payload': {'reasonCode': 'bot_unavailable'},
      });

      expect(provider.matchmakingState, PvpMatchmakingState.idle);
      provider.dispose();
    });
  });
}
