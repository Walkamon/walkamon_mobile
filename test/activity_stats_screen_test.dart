import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/daily_step_statistic_response.dart';
import 'package:walkamon_mobile/screen/profile/activity_stats_screen.dart';

void main() {
  group('dynamic chart maximum', () {
    test('starts at 1000 steps', () {
      expect(calculateDynamicChartMaximum(const []), 1000);
      expect(
        calculateDynamicChartMaximum(const [
          StepChartPoint(label: 'Today', steps: 699),
        ]),
        1000,
      );
    });

    test('grows by 1000 when steps reach 70 percent of the scale', () {
      expect(
        calculateDynamicChartMaximum(const [
          StepChartPoint(label: 'Today', steps: 700),
        ]),
        2000,
      );
      expect(
        calculateDynamicChartMaximum(const [
          StepChartPoint(label: 'Today', steps: 1400),
        ]),
        3000,
      );
    });

    test('uses the highest chart value', () {
      expect(
        calculateDynamicChartMaximum(const [
          StepChartPoint(label: 'Monday', steps: 200),
          StepChartPoint(label: 'Tuesday', steps: 700),
          StepChartPoint(label: 'Wednesday', steps: 500),
        ]),
        2000,
      );
    });
  });

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
