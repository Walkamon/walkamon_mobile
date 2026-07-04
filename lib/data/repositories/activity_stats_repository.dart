import '../../../core/network/api_response.dart';
import '../datasources/remote/activity_stats_datasource.dart';
import '../models/daily_step_statistic_response.dart';

class ActivityStatsRepository {
  ActivityStatsRepository({ActivityStatsDatasource? datasource})
      : _datasource = datasource ?? ActivityStatsDatasource();

  final ActivityStatsDatasource _datasource;

  Future<DailyStepStatisticResponse> getStatistic(
    ActivityStatsRange range, {
    DateTime? date,
  }) async {
    final apiResponse = await _datasource.getStatistic(range, date: date);

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Khong the tai thong ke hoat dong.',
    );
  }
}
