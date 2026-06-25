import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class SettingScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<bool> logout() async {
    try {
      final response = await _apiClient.post<dynamic>(ApiConstants.logout);
      return response.success;
    } catch (_) {
      return false;
    }
  }

  Future<ApiResponse<void>> sendFeedback({
    required String content,
    required String feedbackTypeCode,
  }) async {
    return await _apiClient.post<void>(
      ApiConstants.userFeedback,
      data: {'Content': content, 'FeedbackTypeCode': feedbackTypeCode},
      fromJsonT: (_) => null,
    );
  }
}
