import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../../core/network/api_response.dart';
import '../datasources/remote/login_screen_datasource.dart';
import '../models/login_response.dart';

class LoginScreenRepository {
  final LoginScreenDatasource _datasource = LoginScreenDatasource();

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    // 1. Chờ Datasource gọi API lên server và lấy kết quả về
    final response = await _datasource.login(email: email, password: password);

    // 2. Nếu đăng nhập thành công và có dữ liệu trả về -> Bắt đầu "cất két"
    if (response.success && response.data != null) {
      final prefs = await SharedPreferences.getInstance();

      final token = response.data!.token;

      if (token.isNotEmpty) {
        // Cất token vào két với ổ khóa tên là 'access_token' (Giống hệt bên Interceptor)
        await prefs.setString('access_token', token);
      }
    }

    // 3. Trả kết quả về cho UI hoặc Provider như bình thường
    return response;
  }
}
