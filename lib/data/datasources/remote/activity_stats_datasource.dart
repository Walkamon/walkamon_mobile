import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/daily_step_statistic_response.dart';

enum ActivityStatsRange { daily, weekly, monthly }

class ActivityStatsDatasource {
  ActivityStatsDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<DailyStepStatisticResponse>> getStatistic(
    ActivityStatsRange range, {
    DateTime? date,
  }) async {
    final path = switch (range) {
      ActivityStatsRange.daily => '/api/Static-steps/daily',
      ActivityStatsRange.weekly => '/api/Static-steps/weekly',
      ActivityStatsRange.monthly => '/api/Static-steps/monthly',
    };

    final queryParameters = <String, dynamic>{};
    if (date != null) {
      queryParameters['date'] = date.toIso8601String().split('T').first;
    }

    return _apiClient.get<DailyStepStatisticResponse>(
      path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      fromJsonT: (json) => DailyStepStatisticResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}
