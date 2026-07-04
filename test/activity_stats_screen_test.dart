import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/daily_step_statistic_response.dart';
import 'package:walkamon_mobile/screen/profile/activity_stats_screen.dart';

void main() {
  test('monthly stats are grouped into four weekly buckets', () {
    final data = List.generate(
      30,
      (index) => DailyStepStatisticItemResponse(
        label: 'day-$index',
        stepCount: 1,
      ),
    );

    final points = buildChartPointsForRange(
      range: ActivityTimeRange.monthly,
      data: data,
    );

    expect(points.length, 4);
    expect(points.map((point) => point.label).toList(), [
      'Tuần 1',
      'Tuần 2',
      'Tuần 3',
      'Tuần 4',
    ]);
    expect(points.fold<int>(0, (sum, point) => sum + point.steps), 30);
  });
}
