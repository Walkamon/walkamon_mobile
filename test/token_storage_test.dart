import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkamon_mobile/core/auth/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clearAuthData removes persisted auth data and cached token', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'access-token',
      'jwt': 'jwt-token',
      'refresh_token': 'refresh-token',
      'user_id': 'user-123',
    });

    final prefs = await SharedPreferences.getInstance();
    TokenStorage.setToken('cached-token');

    await TokenStorage.clearAuthData();

    expect(TokenStorage.token, isNull);
    expect(prefs.getString('access_token'), isNull);
    expect(prefs.getString('jwt'), isNull);
    expect(prefs.getString('refresh_token'), isNull);
    expect(prefs.getString('user_id'), isNull);
  });
}
