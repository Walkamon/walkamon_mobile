import '../../../core/network/api_response.dart';
import '../datasources/remote/achievement_screen_datasource.dart';
import '../models/achievement_response.dart';

class AchievementScreenRepository {
  final AchievementScreenDatasource _remoteDatasource;

  AchievementScreenRepository(this._remoteDatasource);

  Future<List<AchievementResponse>> getAchievements() async {
    final apiResponse = await _remoteDatasource.getAchievements();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải danh sách thành tựu.',
    );
  }
}
