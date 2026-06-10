import '../../core/network/api_response.dart';
import '../datasources/remote/login_screen_datasource.dart';
import '../models/login_response.dart';

class LoginScreenRepository {
  final LoginScreenDatasource _datasource = LoginScreenDatasource();

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) {
    // Đơn giản là chuyển tiếp lệnh xuống Datasource để xử lý
    return _datasource.login(email: email, password: password);
  }
}
