import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/app_failure.dart';

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
      ApiConstants.dailyLoginCalendar, // Sử dụng hằng số thay vì chuỗi cứng
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    if (!response.success) throw response.failure;
    if (response.data == null) {
      throw const AppFailure(
        code: 'UNEXPECTED_RESPONSE',
        status: 200,
        fallbackMessage: 'Daily login response did not contain data.',
      );
    }
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> claimDailyReward() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.claimDailyReward, // Sử dụng hằng số thay vì chuỗi cứng
      fromJsonT: (json) {
        // Log này giúp bạn nhìn thấy chính xác Server trả về ruột "data" là gì trước khi qua ApiClient

        return json as Map<String, dynamic>;
      },
    );
    if (!response.success) throw response.failure;
    if (response.data == null) {
      throw const AppFailure(
        code: 'UNEXPECTED_RESPONSE',
        status: 200,
        fallbackMessage: 'Daily reward response did not contain data.',
      );
    }
    return response.data!;
  }
}
