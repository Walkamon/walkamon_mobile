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
    // Gọi hàm post của ApiClient, truyền kiểu dữ liệu mong muốn là <LoginResponse>
    return await _apiClient.post<LoginResponse>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      // Đưa khuôn mẫu từ Model vào để ApiClient tự động parse dữ liệu sạch ra ngoài
      fromJsonT: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
