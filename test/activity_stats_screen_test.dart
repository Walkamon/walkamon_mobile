import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/datasources/remote/activity_stats_datasource.dart';
import 'package:walkamon_mobile/data/models/daily_step_statistic_response.dart';
import 'package:walkamon_mobile/data/repositories/activity_stats_repository.dart';
import 'package:walkamon_mobile/screen/profile/activity_stats_screen.dart';

class _RecordingActivityStatsRepository extends ActivityStatsRepository {
  final List<ActivityStatsRange> requestedRanges = [];

  @override
  Future<DailyStepStatisticResponse> getStatistic(
    ActivityStatsRange range, {
    DateTime? date,
  }) async {
    requestedRanges.add(range);
    return DailyStepStatisticResponse(
      type: range.name,
      fromDate: null,
      toDate: null,
      data: const [],
    );
  }
}

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

  test('monthly stats are split into pages of seven days', () {
    final data = List.generate(
      16,
      (index) => DailyStepStatisticItemResponse(
        label: 'day-$index',
        stepCount: index + 1,
      ),
    );

    final points = buildChartPointsForRange(
      range: ActivityTimeRange.monthly,
      data: data,
    );
    final pages = buildWeeklyChartPages(points);

    expect(pages.length, 3);
    expect(pages[0].length, 7);
    expect(pages[1].length, 7);
    expect(pages[2].length, 2);
    expect(pages[0].first.label, 'day-0');
    expect(pages[1].first.label, 'day-7');
    expect(pages[2].first.label, 'day-14');
    expect(
      pages
          .expand((page) => page)
          .fold<int>(0, (sum, point) => sum + point.steps),
      136,
    );
  });

  test('weekly stats use the weekly endpoint range', () async {
    final repository = _RecordingActivityStatsRepository();
    final screenRepository = ActivityStatsScreenRepository(
      repository: repository,
    );

    await screenRepository.getStats(ActivityTimeRange.weekly);

    expect(repository.requestedRanges, [ActivityStatsRange.weekly]);
  });

  test('monthly stats use the monthly endpoint range', () async {
    final repository = _RecordingActivityStatsRepository();
    final screenRepository = ActivityStatsScreenRepository(
      repository: repository,
    );

    await screenRepository.getStats(ActivityTimeRange.monthly);

    expect(repository.requestedRanges, [ActivityStatsRange.monthly]);
  });
}
