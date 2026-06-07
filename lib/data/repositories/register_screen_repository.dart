import '../datasources/remote/register_screen_datasource.dart';
import '../../core/network/api_response.dart';
import '../models/register_response.dart';

class RegisterScreenRepository {
  final RegisterScreenDatasource _remoteDataSource = RegisterScreenDatasource();

  Future<ApiResponse<RegisterResponse>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    return await _remoteDataSource.register(
      email: email,
      username: username,
      password: password,
    );
  }
}
