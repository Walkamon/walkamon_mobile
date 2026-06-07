/*
    "Cấu hình đường truyền mạng" nằm ngay trên thiết bị điện thoại của người dùng (Client).
    Ví dụ: Nó đặt ra luật là: "Mọi yêu cầu gửi đi hay nhận về chỉ được phép chờ tối đa 10 giây (connectTimeout), nếu quá 10 giây mà server chưa trả lời thì tự hủy kết nối để tránh làm đơ app của người dùng".
*/

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioProvider {
  static Dio? _instance;

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Thêm AuthInterceptor
      _instance!.interceptors.add(AuthInterceptor());

      // Thêm LogInterceptor để in log request/response
      _instance!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
    return _instance!;
  }
}
