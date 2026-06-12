/*
   Khi bạn đang dùng app mà Token đăng nhập bị hết hạn, server sẽ trả về lỗi 401 Unauthorized. File này sẽ tự động chặn lỗi này lại, âm thầm gọi API lấy Token mới (Refresh Token), cập nhật lại Token mới vào máy, rồi gửi lại request bị lỗi ban đầu. Tất cả diễn ra ngầm, người dùng không hề biết và không bị văng ra màn hình đăng nhập.
*/

import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  // Tạo một thực thể Dio riêng để gọi API Refresh, tránh bị lặp vô hạn (vòng lặp vô tận Interceptor)
  final Dio _refreshDio = Dio(
    BaseOptions(baseUrl: 'https://walkamon.azurewebsites.net'),
  );

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Kiểm tra nếu Server trả về lỗi 401 (Hết hạn Token / Không có quyền)
    if (err.response?.statusCode == 401) {
      try {
        // 2. Gọi API để lấy Access Token mới bằng Refresh Token
        // Giả sử API refresh của bạn của bạn là /auth/refresh hoặc /api/v1/auth/refresh
        final response = await _refreshDio.post(
          '/auth/refresh',
          options: Options(
            headers: {
              // Thường server sẽ cần gửi kèm token cũ hoặc một token refresh riêng trong header/body
              'Authorization': 'Bearer ${TokenStorage.token}',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          // 3. Giả sử API trả về chuỗi token mới trong: response.data['data']['token']
          // Bạn hãy check lại với bạn của bạn xem cấu trúc chuẩn là gì nhé!
          final newToken = response.data['data']['token'] as String;

          // 4. Cập nhật Token mới vào két sắt TokenStorage (Lưu cả RAM và Local Storage)
          TokenStorage.setToken(newToken);

          // 5. Thay thế token cũ trong Request bị lỗi bằng Token mới tinh vừa lấy
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          // 6. Tạo một bản clone Dio để thực thi lại Request cũ xem như chưa từng có cuộc chia ly
          final cloneDio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
          final retryResponse = await cloneDio.request(
            requestOptions.path,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
          );

          // Trả kết quả thành công về cho App
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // Nếu API Refresh cũng lỗi (Ví dụ: Refresh token quá hạn, người dùng đổi mật khẩu...)
        // Lập tức đăng xuất, xóa token và đá người dùng ra màn hình Login
        TokenStorage.clear();
        // Bạn có thể thông báo qua EventBus hoặc chuyển trang ở đây nếu cần
      }
    }

    // Nếu không phải lỗi 401 hoặc refresh thất bại, trả lỗi về cho App xử lý bình thường
    super.onError(err, handler);
  }
}
