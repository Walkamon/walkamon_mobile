/*
    "Cấu hình đường truyền mạng" nằm ngay trên thiết bị điện thoại của người dùng (Client).
    Ví dụ: Nó đặt ra luật là: "Mọi yêu cầu gửi đi hay nhận về chỉ được phép chờ tối đa 10 giây (connectTimeout), nếu quá 10 giây mà server chưa trả lời thì tự hủy kết nối để tránh làm đơ app của người dùng".
*/

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioProvider {
  static Dio? _instance;
  static String _languageCode = 'vi-VN';

  /// Keeps the API locale aligned with the locale currently rendered by
  /// Flutter.  The server uses this header before falling back to the profile
  /// preference, so every newly-created request gets the same language.
  static void setLanguageCode(String languageCode) {
    final normalized = languageCode.trim();
    if (normalized.isNotEmpty) _languageCode = normalized;
  }

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': '*/*'},
        ),
      );

      _instance!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Accept-Language'] = _languageCode;
            handler.next(options);
          },
        ),
      );

      // Thêm AuthInterceptor
      _instance!.interceptors.add(AuthInterceptor());

      // Thêm LogInterceptor để in log request/response
      // _instance!.interceptors.add(
      //   LogInterceptor(
      //     requestBody: true,
      //     responseBody: true,
      //   ),
      // );
    }
    return _instance!;
  }
}
