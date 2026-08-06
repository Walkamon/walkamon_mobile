import '../datasources/remote/forgot_password_screen_datasource.dart';
import '../../core/network/api_response.dart';
import '../models/otp_sent_response.dart';
import '../models/forgot_password_reset_ticket_response.dart';

class ForgotPasswordScreenRepository {
  final ForgotPasswordScreenDatasource _remoteDataSource =
      ForgotPasswordScreenDatasource();

  Future<ApiResponse<OtpSentResponse>> forgotPassword({
    required String email,
  }) async {
    return await _remoteDataSource.forgotPassword(email: email);
  }

  Future<ApiResponse<void>> resetForgotPassword({
    required String requestCode,
    required String otp,
    required String newPassword,
  }) async {
    return await _remoteDataSource.resetForgotPassword(
      requestCode: requestCode,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<ApiResponse<ForgotPasswordResetTicketResponse>>
  verifyForgotPasswordOtp({required String requestCode, required String otp}) {
    return _remoteDataSource.verifyForgotPasswordOtp(
      requestCode: requestCode,
      otp: otp,
    );
  }

  Future<ApiResponse<void>> resetForgotPasswordWithTicket({
    required String resetToken,
    required String newPassword,
  }) {
    return _remoteDataSource.resetForgotPasswordWithTicket(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}
