import '../datasources/remote/change_password_screen_datasource.dart';
import '../../core/network/api_response.dart';

class ChangePasswordScreenRepository {
  ChangePasswordScreenRepository({ChangePasswordScreenDatasource? datasource})
    : _remoteDataSource = datasource ?? ChangePasswordScreenDatasource();

  final ChangePasswordScreenDatasource _remoteDataSource;

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
