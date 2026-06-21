import '../../core/network/api_response.dart';
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
    throw Exception(resp.message);
  }

  Future<ClaimMissionRewardResponse> claimMission(String missionId) async {
    final resp = await _remoteDataSource.claimMission(missionId);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw Exception(resp.message);
  }

  Future<PlayerChallengeStateResponse> getChallengeState() async {
    final resp = await _remoteDataSource.getChallengeState();
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw Exception(resp.message);
  }

  Future<ApiResponse<PlayerChallengeStateResponse>> createRandomChallenge() async {
    return await _remoteDataSource.createRandomChallenge();
  }

  Future<ApiResponse<CancelPlayerChallengeResponse>> cancelChallenge(
    String userMissionId,
  ) async {
    return await _remoteDataSource.cancelChallenge(userMissionId);
  }
}
