import '../../../core/network/app_failure.dart';
import '../datasources/remote/achievement_screen_datasource.dart';
import '../models/achievement_response.dart';
import '../models/achievement_claim_response.dart';

class AchievementScreenRepository {
  final AchievementScreenDatasource _remoteDatasource;

  AchievementScreenRepository(this._remoteDatasource);

  Future<List<AchievementResponse>> getAchievements() async {
    final apiResponse = await _remoteDatasource.getAchievements();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<ClaimAchievementRewardResponse> claimAchievement(
    String achievementId,
  ) async {
    final resp = await _remoteDatasource.claimAchievement(achievementId);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }
}
