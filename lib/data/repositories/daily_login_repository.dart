import '../datasources/remote/daily_login_datasource.dart';
import '../models/daily_login_model.dart';
import '../../core/network/api_client.dart';

class DailyLoginRepository {
  final DailyLoginDatasource _datasource;

  DailyLoginRepository({DailyLoginDatasource? datasource})
      : _datasource = datasource ?? DailyLoginDatasourceImpl(ApiClient());

  Future<DailyLoginCalendarData> getDailyLoginStatus() async {
    try {
      final data = await _datasource.getDailyLoginStatus();
      return DailyLoginCalendarData.fromJson(data);
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin điểm danh: $e');
    }
  }

  Future<bool> claimDailyReward() async {
    try {
      final _ = await _datasource.claimDailyReward();
      return true;
    } catch (e) {
      throw Exception('Lỗi khi nhận thưởng điểm danh: $e');
    }
  }
}
