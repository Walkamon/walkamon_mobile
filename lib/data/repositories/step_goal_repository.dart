import '../../core/network/app_failure.dart';
import '../datasources/remote/step_goal_datasource.dart';
import '../models/step_goal_response.dart';

class StepGoalRepository {
  StepGoalRepository({StepGoalDatasource? datasource})
    : _datasource = datasource ?? StepGoalDatasource();

  final StepGoalDatasource _datasource;

  Future<GoalProgressResponse> getProgress() async {
    final apiResponse = await _datasource.getProgress();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<CurrentStreakResponse> getCurrentStreak() async {
    final apiResponse = await _datasource.getCurrentStreak();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<LongestStreakResponse> getLongestStreak() async {
    final apiResponse = await _datasource.getLongestStreak();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<void> setGoal(int targetSteps) async {
    final apiResponse = await _datasource.setGoal(targetSteps);

    if (apiResponse.success) return;

    throw apiResponse.failure;
  }

  Future<StepGoalClaimRewardResponse> claimReward() async {
    final apiResponse = await _datasource.claimReward();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }
}
