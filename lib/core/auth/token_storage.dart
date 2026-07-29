import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static String? _token;

  static String? get token => _token;

  static void setToken(String? token) => _token = token;

  static void clear() => _token = null;

  static Future<void> clearAuthData() async {
    clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('jwt');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
  }
}
