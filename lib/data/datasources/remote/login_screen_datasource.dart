import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/login_response.dart';

class LoginScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    return _apiClient.post<LoginResponse>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJsonT: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<LoginResponse>> googleLogin({
    required String idToken,
  }) async {
    return _apiClient.post<LoginResponse>(
      ApiConstants.googleLogin,
      data: {'idToken': idToken},
      fromJsonT: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
