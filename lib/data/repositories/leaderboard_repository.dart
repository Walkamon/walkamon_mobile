import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/leaderboard_response.dart';

class LeaderboardRepository {
  LeaderboardRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<LeaderboardResponse>> getLeaderboard(String type) async {
    return _apiClient.get<LeaderboardResponse>(
      '/api/Leaderboard/leaderboard',
      queryParameters: {'type': type},
      fromJsonT: (json) => LeaderboardResponse.fromJson(json),
    );
  }
}
