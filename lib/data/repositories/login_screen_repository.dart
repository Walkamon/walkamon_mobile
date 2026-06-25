import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_response.dart';
import '../datasources/remote/login_screen_datasource.dart';
import '../models/login_response.dart';

class LoginScreenRepository {
  final LoginScreenDatasource _datasource = LoginScreenDatasource();

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _datasource.login(email: email, password: password);
    await _persistTokenIfPresent(response);
    return response;
  }

  Future<ApiResponse<LoginResponse>> googleLogin({
    required String idToken,
  }) async {
    final response = await _datasource.googleLogin(idToken: idToken);
    await _persistTokenIfPresent(response);
    return response;
  }

  Future<void> _persistTokenIfPresent(
    ApiResponse<LoginResponse> response,
  ) async {
    if (response.success && response.data != null) {
      final token = response.data!.token;

      if (token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
      }
    }
  }
}
