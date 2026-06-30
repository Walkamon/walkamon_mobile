import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/achievement_response.dart';

class AchievementScreenDatasource {
  final ApiClient _apiClient;

  AchievementScreenDatasource(this._apiClient);

  Future<ApiResponse<List<AchievementResponse>>> getAchievements() async {
    return await _apiClient.get<List<AchievementResponse>>(
      ApiConstants.achievements,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .map(
                (e) => AchievementResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
        return <AchievementResponse>[];
      },
    );
  }
}
