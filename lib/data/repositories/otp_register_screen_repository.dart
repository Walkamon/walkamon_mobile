import '../datasources/remote/otp_register_screen_datasource.dart';
import '../../core/network/api_response.dart';
import '../models/register_response.dart';

class OtpScreenRepository {
  final OtpScreenDatasource _remoteDataSource = OtpScreenDatasource();

  Future<ApiResponse<void>> verifyOtp({
    required String requestCode,
    required String otp,
  }) async {
    return await _remoteDataSource.verifyOtp(
      requestCode: requestCode,
      otp: otp,
    );
  }

  Future<ApiResponse<RegisterResponse>> resendOtp({
    required String requestCode,
  }) async {
    return await _remoteDataSource.resendOtp(requestCode: requestCode);
  }
}
