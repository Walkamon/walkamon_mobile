import '../../../core/network/api_client.dart';

abstract class DailyLoginDatasource {
  Future<Map<String, dynamic>> getDailyLoginStatus();
  Future<Map<String, dynamic>> claimDailyReward();
}

class DailyLoginDatasourceImpl implements DailyLoginDatasource {
  final ApiClient _apiClient;

  DailyLoginDatasourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getDailyLoginStatus() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/daily-login-rewards/calendar',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> claimDailyReward() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/daily-login-rewards/claim',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return response.data ?? {};
  }
}
