import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';

class ChangePasswordScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final Map<String, dynamic> body = {
      'CurrentPassword': currentPassword,
      'NewPassword': newPassword,
    };

    return await _apiClient.put<void>(ApiConstants.changePassword, data: body);
  }
}
