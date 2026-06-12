import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 1. ƯU TIÊN 1: Thử bốc Token từ RAM (Cách của Upstream)
      String? token = TokenStorage.token;

      // 2. ƯU TIÊN 2: Nếu RAM trống, lôi ổ cứng ra tìm (Cách của Stashed)
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('access_token');
      }

      // 3. Nếu tìm thấy (dù ở đâu), dán tem "Bearer" vào Header
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // 4. Cho request đi tiếp
      handler.next(options);
    } catch (e) {
      // Lỗi lục lọi bộ nhớ thì cứ cho đi tiếp
      handler.next(options);
    }
  }
}
