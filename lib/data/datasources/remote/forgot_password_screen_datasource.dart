import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../models/otp_sent_response.dart';

class ForgotPasswordScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<OtpSentResponse>> forgotPassword({
    required String email,
  }) async {
    final Map<String, dynamic> body = {
      'email': email,
    };

    return await _apiClient.post<OtpSentResponse>(
      ApiConstants.forgotPassword,
      data: body,
      fromJsonT: (json) =>
          OtpSentResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> resetForgotPassword({
    required String requestCode,
    required String otp,
    required String newPassword,
  }) async {
    final Map<String, dynamic> body = {
      'requestCode': requestCode,
      'otp': otp,
      'newPassword': newPassword,
    };

    return await _apiClient.post<void>(
      ApiConstants.resetForgotPassword,
      data: body,
    );
  }
}