import '../datasources/remote/daily_login_datasource.dart';
import '../models/daily_login_model.dart';
import '../../core/network/api_client.dart';

class DailyLoginRepository {
  final DailyLoginDatasource _datasource;

  DailyLoginRepository({DailyLoginDatasource? datasource})
    : _datasource = datasource ?? DailyLoginDatasourceImpl(ApiClient());

  Future<DailyLoginCalendarData> getDailyLoginStatus() async {
    final data = await _datasource.getDailyLoginStatus();
    return DailyLoginCalendarData.fromJson(data);
  }

  Future<ClaimDailyRewardData> claimDailyReward() async {
    final data = await _datasource.claimDailyReward();
    return ClaimDailyRewardData.fromJson(data);
  }
}
