import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../models/register_response.dart';

class OtpScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<void>> verifyOtp({
    required String requestCode,
    required String otp,
  }) async {
    final Map<String, dynamic> body = {'requestCode': requestCode, 'otp': otp};
    return await _apiClient.post<void>(ApiConstants.verifyOtp, data: body);
  }

  Future<ApiResponse<RegisterResponse>> resendOtp({
    required String requestCode,
  }) async {
    final Map<String, dynamic> body = {'requestCode': requestCode};
    return await _apiClient.post<RegisterResponse>(
      ApiConstants.resendOtp,
      data: body,
      fromJsonT: (json) =>
          RegisterResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
