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
    if (!response.success || response.data == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Never let an account reuse the previous account's persisted identity.
    await prefs.remove('access_token');
    await prefs.remove('jwt');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');

    final token = response.data!.token;
    if (token.isNotEmpty) {
      await prefs.setString('access_token', token);
    }

    final userId = response.data!.userId;
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString('user_id', userId);
    }
  }
}
