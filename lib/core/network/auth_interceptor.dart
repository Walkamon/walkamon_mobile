/*
   Bộ lọc tự động. Mỗi khi app gửi request lên server (ví dụ: lấy danh sách pet, cập nhật bước chân), file này sẽ tự động lấy Token đăng nhập (JWT Token) đang lưu trên máy dán vào Header của request (Authorization: Bearer <Token>).
*/

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Tạm thời chỉ chuyển tiếp request. 
    // Khi có SharedPreferences / Secure Storage lưu token, ta sẽ lấy và gán vào header tại đây.
    super.onRequest(options, handler);
  }
}
