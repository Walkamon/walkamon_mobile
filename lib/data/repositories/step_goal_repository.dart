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

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải mục tiêu bước chân.',
    );
  }

  Future<CurrentStreakResponse> getCurrentStreak() async {
    final apiResponse = await _datasource.getCurrentStreak();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải chuỗi ngày hiện tại.',
    );
  }

  Future<LongestStreakResponse> getLongestStreak() async {
    final apiResponse = await _datasource.getLongestStreak();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải chuỗi ngày dài nhất.',
    );
  }

  Future<void> setGoal(int targetSteps) async {
    final apiResponse = await _datasource.setGoal(targetSteps);

    if (apiResponse.success) return;

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể lưu mục tiêu bước chân.',
    );
  }

  Future<StepGoalClaimRewardResponse> claimReward() async {
    final apiResponse = await _datasource.claimReward();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể nhận thưởng chuỗi ngày.',
    );
  }
}
