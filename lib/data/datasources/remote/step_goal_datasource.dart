import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/step_goal_response.dart';

class StepGoalDatasource {
  StepGoalDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<GoalProgressResponse>> getProgress() {
    return _apiClient.get<GoalProgressResponse>(
      ApiConstants.stepGoalProgress,
      fromJsonT: (json) =>
          GoalProgressResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<CurrentStreakResponse>> getCurrentStreak() {
    return _apiClient.get<CurrentStreakResponse>(
      ApiConstants.stepGoalCurrentStreak,
      fromJsonT: (json) => CurrentStreakResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<LongestStreakResponse>> getLongestStreak() {
    return _apiClient.get<LongestStreakResponse>(
      ApiConstants.stepGoalLongestStreak,
      fromJsonT: (json) => LongestStreakResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<dynamic>> setGoal(int targetSteps) {
    return _apiClient.post<dynamic>(
      ApiConstants.stepGoal,
      data: {'targetSteps': targetSteps},
    );
  }

  Future<ApiResponse<StepGoalClaimRewardResponse>> claimReward() {
    return _apiClient.post<StepGoalClaimRewardResponse>(
      ApiConstants.stepGoalClaim,
      fromJsonT: (json) => StepGoalClaimRewardResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}
