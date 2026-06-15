import '../datasources/remote/setting_screen_datasource.dart';

class SettingScreenRepository {
  final SettingScreenDatasource _remoteDataSource = SettingScreenDatasource();

  Future<bool> logout() {
    return _remoteDataSource.logout();
  }

  Future<bool> sendFeedback({
    required String content,
    required String feedbackTypeCode,
  }) {
    return _remoteDataSource.sendFeedback(
      content: content,
      feedbackTypeCode: feedbackTypeCode,
    );
  }
}
