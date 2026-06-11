import '../datasources/remote/setting_screen_datasource.dart';

class SettingScreenRepository {
  final SettingScreenDatasource _remoteDataSource = SettingScreenDatasource();

  Future<bool> logout() {
    return _remoteDataSource.logout();
  }
}
