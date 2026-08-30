import '../../core/network/api_response.dart';
import '../../core/network/app_failure.dart';
import '../datasources/remote/missions_screen_datasource.dart';
import '../models/player_challenge_response.dart';
import '../models/player_mission_response.dart';

class MissionsScreenRepository {
  final MissionsScreenDatasource _remoteDataSource = MissionsScreenDatasource();

  Future<PlayerMissionListResponse> getAllMissions() async {
    final resp = await _remoteDataSource.getAllMissions();
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<ClaimMissionRewardResponse> claimMission(String missionId) async {
    final resp = await _remoteDataSource.claimMission(missionId);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<PlayerChallengeStateResponse> getChallengeState() async {
    final resp = await _remoteDataSource.getChallengeState();
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<ClaimChallengeRewardResponse> claimChallenge(
    String userMissionId,
  ) async {
    final resp = await _remoteDataSource.claimChallenge(userMissionId);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<ApiResponse<PlayerChallengeStateResponse>>
  createRandomChallenge() async {
    return await _remoteDataSource.createRandomChallenge();
  }

  Future<ApiResponse<CancelPlayerChallengeResponse>> cancelChallenge(
    String userMissionId,
  ) async {
    return await _remoteDataSource.cancelChallenge(userMissionId);
  }
}
