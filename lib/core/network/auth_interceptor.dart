/*
   Bộ lọc tự động. Mỗi khi app gửi request lên server (ví dụ: lấy danh sách pet, cập nhật bước chân), file này sẽ tự động lấy Token đăng nhập (JWT Token) đang lưu trên máy dán vào Header của request (Authorization: Bearer <Token>).
*/

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
