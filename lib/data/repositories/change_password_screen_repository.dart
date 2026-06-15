import '../datasources/remote/change_password_screen_datasource.dart';
import '../../core/network/api_response.dart';

class ChangePasswordScreenRepository {
  final ChangePasswordScreenDatasource _remoteDataSource =
      ChangePasswordScreenDatasource();

  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
