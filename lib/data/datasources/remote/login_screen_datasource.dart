import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/login_response.dart';

class LoginScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Gọi hàm post của ApiClient
      return await _apiClient.post<LoginResponse>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
        fromJsonT: (json) =>
            LoginResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      // ── BẮT TRIỆT ĐỂ LỖI 400 BAD REQUEST TỪ SERVER .NET ──
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;

        if (errorData is Map) {
          // Trường hợp 1: Lỗi nghiệp vụ (C# tự viết ném ra key 'message')
          if (errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          }

          // Trường hợp 2: Lỗi định dạng FluentValidation (Cấu trúc chứa map 'errors')
          if (errorData.containsKey('errors')) {
            final Map<String, dynamic> validationErrors = errorData['errors'];
            List<String> allMessages = [];

            // Duyệt qua toàn bộ map lỗi để gom hết chuỗi tiếng Anh lại
            validationErrors.forEach((key, value) {
              if (value is List) {
                allMessages.addAll(value.map((item) => item.toString()));
              }
            });

            if (allMessages.isNotEmpty) {
              // Ném chuỗi tiếng Anh sạch ra ngoài (Ví dụ: "Password must be at least 6 characters")
              throw Exception(allMessages.join(', '));
            }
          }
        }
      }
      throw Exception("Không thể kết nối đến máy chủ. Vui lòng thử lại!");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
