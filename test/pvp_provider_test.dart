import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/pvp_sprint_datasource.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';

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

void main() {
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
        final provider = PvpProvider(pvpDatasource: datasource);

        await provider.startMatchmaking();

        expect(provider.matchmakingState, PvpMatchmakingState.waiting);
        expect(datasource.statusCallCount, 1);
      },
    );
  });
}
