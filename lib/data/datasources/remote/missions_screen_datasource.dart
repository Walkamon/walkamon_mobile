import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/player_challenge_response.dart';
import '../../models/player_mission_response.dart';

class MissionsScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<PlayerMissionListResponse>> getAllMissions() async {
    return await _apiClient.get<PlayerMissionListResponse>(
      ApiConstants.missions,
      fromJsonT: (json) =>
          PlayerMissionListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClaimMissionRewardResponse>> claimMission(
    String missionId,
  ) async {
    return await _apiClient.post<ClaimMissionRewardResponse>(
      ApiConstants.claimMission(missionId),
      fromJsonT: (json) =>
          ClaimMissionRewardResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PlayerChallengeStateResponse>> getChallengeState() async {
    return await _apiClient.get<PlayerChallengeStateResponse>(
      ApiConstants.challengeRandom,
      fromJsonT: (json) =>
          PlayerChallengeStateResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClaimChallengeRewardResponse>> claimChallenge(
    String userMissionId,
  ) async {
    return await _apiClient.post<ClaimChallengeRewardResponse>(
      ApiConstants.claimChallenge(userMissionId),
      fromJsonT: (json) =>
          ClaimChallengeRewardResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PlayerChallengeStateResponse>>
  createRandomChallenge() async {
    return await _apiClient.post<PlayerChallengeStateResponse>(
      ApiConstants.challengeRandom,
      fromJsonT: (json) =>
          PlayerChallengeStateResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CancelPlayerChallengeResponse>> cancelChallenge(
    String userMissionId,
  ) async {
    return await _apiClient.patch<CancelPlayerChallengeResponse>(
      ApiConstants.cancelChallenge(userMissionId),
      fromJsonT: (json) =>
          CancelPlayerChallengeResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
