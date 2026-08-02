import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_dual_bottom_tabs.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/remote/activity_stats_datasource.dart';
import '../../data/models/daily_step_statistic_response.dart';
import '../../data/repositories/activity_stats_repository.dart';
import '../../l10n/app_localizations.dart';

enum _MainTab { stats, history }

enum ActivityTimeRange { daily, weekly, monthly }

String formatStepCount(int steps) {
  return steps.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

class StepChartPoint {
  const StepChartPoint({required this.label, required this.steps});

  final String label;
  final int steps;
}

class StepStatsResponse {
  const StepStatsResponse({
    required this.title,
    required this.averageLabel,
    required this.totalSteps,
    required this.averageSteps,
    required this.totalDistanceKm,
    required this.goal,
    required this.chartData,
  });

  final String title;
  final String averageLabel;
  final int totalSteps;
  final int averageSteps;
  final double totalDistanceKm;
  final int goal;
  final List<StepChartPoint> chartData;
}

class StepHistoryItem {
  const StepHistoryItem({
    required this.formattedDate,
    required this.steps,
    required this.goal,
  });

  final String formattedDate;
  final int steps;
  final int goal;

  bool get isGoalReached => goal > 0 && steps >= goal;
}

List<StepChartPoint> buildChartPointsForRange({
  required ActivityTimeRange range,
  required List<DailyStepStatisticItemResponse> data,
}) {
  return data.map((item) {
    return StepChartPoint(label: item.label, steps: item.stepCount);
  }).toList();
}

List<List<StepChartPoint>> buildWeeklyChartPages(
  Iterable<StepChartPoint> data,
) {
  final points = data.toList();
  if (points.isEmpty) return const [];

  return List.generate((points.length / 7).ceil(), (index) {
    final start = index * 7;
    final end = (start + 7).clamp(0, points.length);
    return points.sublist(start, end);
  });
}

int calculateDynamicChartMaximum(Iterable<StepChartPoint> data) {
  const stepSize = 1000;
  const growThreshold = 0.7;
  final highestSteps = data.fold<int>(
    0,
    (highest, point) => point.steps > highest ? point.steps : highest,
  );
  var maximum = stepSize;

  while (highestSteps >= maximum * growThreshold) {
    maximum += stepSize;
  }

  return maximum;
}

class ActivityStatsScreenRepository {
  ActivityStatsScreenRepository({ActivityStatsRepository? repository})
    : _repository = repository ?? ActivityStatsRepository();

  final ActivityStatsRepository _repository;
  Future<DailyStepStatisticResponse>? _monthlyResponse;

  Future<DailyStepStatisticResponse> _getMonthlyResponse() {
    return _monthlyResponse ??= _repository.getStatistic(
      ActivityStatsRange.monthly,
    );
  }

  Future<StepStatsResponse> getStats(ActivityTimeRange range) async {
    final response = range == ActivityTimeRange.daily
        ? await _repository.getStatistic(ActivityStatsRange.daily)
        : await _getMonthlyResponse();
    final chartData = buildChartPointsForRange(
      range: range,
      data: response.data,
    );
    final totalSteps = chartData.fold(0, (sum, point) => sum + point.steps);
    final averageSteps = chartData.isEmpty
        ? 0
        : (totalSteps / chartData.length).round();

    return StepStatsResponse(
      title: '',
      averageLabel: '',
      totalSteps: totalSteps,
      averageSteps: averageSteps,
      totalDistanceKm: totalSteps * 0.0007,
      goal: calculateDynamicChartMaximum(chartData),
      chartData: chartData,
    );
  }

  Future<List<StepHistoryItem>> getHistory() async {
    final response = await _getMonthlyResponse();

    return buildChartPointsForRange(
      range: ActivityTimeRange.monthly,
      data: response.data,
    ).reversed.map((point) {
      return StepHistoryItem(
        formattedDate: point.label,
        steps: point.steps,
        goal: calculateDynamicChartMaximum([point]),
      );
    }).toList();
  }
}

class ActivityStatsScreen extends StatefulWidget {
  const ActivityStatsScreen({super.key});

  @override
  State<ActivityStatsScreen> createState() => _ActivityStatsScreenState();
}

class _ActivityStatsScreenState extends State<ActivityStatsScreen> {
  final ActivityStatsScreenRepository _repository =
      ActivityStatsScreenRepository();

  _MainTab _activeTab = _MainTab.stats;
  ActivityTimeRange _timeRange = ActivityTimeRange.weekly;

  bool _isStatsLoading = true;
  bool _isHistoryLoading = true;
  String? _statsError;
  String? _historyError;

  StepStatsResponse? _stats;
  List<StepHistoryItem> _history = [];
  int _selectedWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadHistory();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isStatsLoading = true;
      _statsError = null;
    });

    try {
      final stats = await _repository.getStats(_timeRange);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        if (_timeRange != ActivityTimeRange.daily) {
          final pages = buildWeeklyChartPages(stats.chartData);
          _selectedWeekIndex = pages.isEmpty ? 0 : pages.length - 1;
        }
        _isStatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString().replaceAll('Exception: ', '');
        _isStatsLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });

    try {
      final history = await _repository.getHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _isHistoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString().replaceAll('Exception: ', '');
        _isHistoryLoading = false;
      });
    }
  }

  void _onTimeRangeChanged(ActivityTimeRange range) {
    if (_timeRange == range) return;
    setState(() => _timeRange = range);
    _loadStats();
  }

  List<List<StepChartPoint>> _weekPages(StepStatsResponse stats) {
    return buildWeeklyChartPages(stats.chartData);
  }

  StepStatsResponse _visibleStats(StepStatsResponse stats) {
    if (_timeRange == ActivityTimeRange.daily) return stats;
    final pages = _weekPages(stats);
    if (pages.isEmpty) return stats;
    final index = _selectedWeekIndex.clamp(0, pages.length - 1);
    final chartData = pages[index];
    final totalSteps = chartData.fold<int>(
      0,
      (sum, point) => sum + point.steps,
    );

    return StepStatsResponse(
      title: stats.title,
      averageLabel: stats.averageLabel,
      totalSteps: totalSteps,
      averageSteps: chartData.isEmpty
          ? 0
          : (totalSteps / chartData.length).round(),
      totalDistanceKm: totalSteps * 0.0007,
      goal: calculateDynamicChartMaximum(chartData),
      chartData: chartData,
    );
  }

  int _chartGoal(StepStatsResponse stats) {
    return calculateDynamicChartMaximum(stats.chartData);
  }

  int _displayTotal(StepStatsResponse stats) {
    if (stats.totalSteps > 0) return stats.totalSteps;
    return stats.chartData.fold(0, (sum, point) => sum + point.steps);
  }

  int _displayAverage(StepStatsResponse stats) {
    if (stats.averageSteps > 0) return stats.averageSteps;
    if (stats.chartData.isEmpty) return 0;
    return (_displayTotal(stats) / stats.chartData.length).round();
  }

  double _displayDistance(StepStatsResponse stats) {
    if (stats.totalDistanceKm > 0) return stats.totalDistanceKm;
    return _displayTotal(stats) * 0.0007;
  }

  String _averageSuffix() {
    final l10n = AppLocalizations.of(context);
    return _timeRange == ActivityTimeRange.monthly
        ? l10n.activityStatsStepsUnit
        : l10n.activityStatsStepsPerDay;
  }

  String _rangeTitle(ActivityTimeRange range) {
    final l10n = AppLocalizations.of(context);
    return switch (range) {
      ActivityTimeRange.daily => l10n.activityStatsTodayTitle,
      ActivityTimeRange.weekly => l10n.activityStatsWeekTitle,
      ActivityTimeRange.monthly => l10n.activityStatsMonthTitle,
    };
  }

  String _averageLabel(ActivityTimeRange range) {
    final l10n = AppLocalizations.of(context);
    return range == ActivityTimeRange.daily
        ? l10n.activityStatsTotal
        : l10n.activityStatsAverage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cardColor = AppColors.authCard.withValues(alpha: 0.97);
    const primary = AppColors.buttonGreen;
    const onPrimary = AppColors.buttonText;
    const muted = AppColors.parchment;
    const mutedForeground = AppColors.outlineBrown;
    const borderColor = AppColors.wood;
    const foreground = AppColors.woodDeep;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _MainTabBar(
        activeTab: _activeTab,
        cardColor: cardColor,
        borderColor: borderColor,
        primary: primary,
        onPrimary: onPrimary,
        mutedForeground: mutedForeground,
        onChanged: (tab) => setState(() => _activeTab = tab),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _Header(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    final offset = _activeTab == _MainTab.stats
                        ? Tween<Offset>(
                            begin: const Offset(-0.05, 0),
                            end: Offset.zero,
                          )
                        : Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offset.animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _activeTab == _MainTab.stats
                      ? _buildStatsTab(
                          key: const ValueKey('stats'),
                          theme: theme,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          primary: primary,
                          muted: muted,
                          mutedForeground: mutedForeground,
                          foreground: foreground,
                          l10n: l10n,
                        )
                      : _buildHistoryTab(
                          key: const ValueKey('history'),
                          cardColor: cardColor,
                          borderColor: borderColor,
                          primary: primary,
                          muted: muted,
                          mutedForeground: mutedForeground,
                          foreground: foreground,
                          l10n: l10n,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab({
    required Key key,
    required ThemeData theme,
    required Color cardColor,
    required Color borderColor,
    required Color primary,
    required Color muted,
    required Color mutedForeground,
    required Color foreground,
    required AppLocalizations l10n,
  }) {
    if (_isStatsLoading) {
      return Center(
        key: key,
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (_statsError != null) {
      return _ErrorState(
        key: key,
        message: _statsError!,
        onRetry: _loadStats,
        primary: primary,
      );
    }

    final sourceStats = _stats!;
    final stats = _visibleStats(sourceStats);
    final weekPages = _weekPages(sourceStats);
    final goal = _chartGoal(stats);
    final total = _displayTotal(stats);
    final average = _displayAverage(stats);
    final distance = _displayDistance(stats);

    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeRangeSelector(
                timeRange: _timeRange,
                muted: muted,
                cardColor: cardColor,
                borderColor: borderColor,
                mutedForeground: mutedForeground,
                foreground: foreground,
                onChanged: _onTimeRangeChanged,
              ),
              if (_timeRange != ActivityTimeRange.daily &&
                  weekPages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Tuần trước',
                      onPressed: _selectedWeekIndex > 0
                          ? () => setState(() => _selectedWeekIndex--)
                          : null,
                      icon: const AppIcon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${l10n.activityStatsWeekBucket(_selectedWeekIndex + 1)}'
                      '/${weekPages.length}',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tuần tiếp theo',
                      onPressed: _selectedWeekIndex < weekPages.length - 1
                          ? () => setState(() => _selectedWeekIndex++)
                          : null,
                      icon: const AppIcon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      _timeRange == ActivityTimeRange.daily
                          ? Icons.schedule_outlined
                          : _timeRange == ActivityTimeRange.monthly
                          ? Icons.directions_walk_outlined
                          : Icons.trending_up_outlined,
                      asset: _timeRange == ActivityTimeRange.monthly
                          ? AppAssets.iconProfileSteps
                          : null,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rangeTitle(_timeRange),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: mutedForeground,
                            ),
                            children: [
                              TextSpan(text: '${_averageLabel(_timeRange)}: '),
                              TextSpan(
                                text: formatStepCount(average),
                                style: TextStyle(color: primary),
                              ),
                              TextSpan(text: ' ${_averageSuffix()}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 256,
                child: stats.chartData.isEmpty
                    ? Center(
                        child: Text(
                          l10n.activityStatsNoChartData,
                          style: TextStyle(
                            color: mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _StepsBarChart(
                        data: stats.chartData,
                        goal: goal,
                        timeRange: _timeRange,
                        l10n: l10n,
                        primary: primary,
                        muted: muted,
                        mutedForeground: mutedForeground,
                        borderColor: borderColor,
                        barWidth: _timeRange == ActivityTimeRange.monthly
                            ? 40
                            : 32,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: l10n.activityStatsTotalSteps,
                value: formatStepCount(total),
                cardColor: cardColor,
                borderColor: borderColor,
                foreground: foreground,
                mutedForeground: mutedForeground,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                label: l10n.activityStatsDistance,
                value: distance.toStringAsFixed(1),
                suffix: l10n.activityStatsSuffixKm,
                cardColor: cardColor,
                borderColor: borderColor,
                foreground: foreground,
                mutedForeground: mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHistoryTab({
    required Key key,
    required Color cardColor,
    required Color borderColor,
    required Color primary,
    required Color muted,
    required Color mutedForeground,
    required Color foreground,
    required AppLocalizations l10n,
  }) {
    Widget content;

    if (_isHistoryLoading) {
      content = Center(child: CircularProgressIndicator(color: primary));
    } else if (_historyError != null) {
      content = _ErrorState(
        message: _historyError!,
        onRetry: _loadHistory,
        primary: primary,
      );
    } else if (_history.isEmpty) {
      content = Center(
        child: GameButtonLabel(
          l10n.activityStatsNoHistory,
          fontSize: 14,
          color: AppColors.woodDeep,
          outlineColor: AppColors.authCard,
          outlineWidth: 3,
          maxLines: 2,
        ),
      );
    } else {
      content = ListView.separated(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _history[index];
          return _HistoryCard(
            item: item,
            cardColor: cardColor,
            borderColor: borderColor,
            primary: primary,
            muted: muted,
            mutedForeground: mutedForeground,
            foreground: foreground,
            l10n: l10n,
          );
        },
      );
    }

    return _ActivityHistoryPanel(
      key: key,
      title: l10n.activityStatsHistory,
      child: content,
    );
  }
}

class _ActivityHistoryPanel extends StatelessWidget {
  const _ActivityHistoryPanel({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.leafLight.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.oliveDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 38, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.authCard.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.wood, width: 1.5),
              ),
              child: child,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 44,
          right: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.woodLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.woodDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GameButtonLabel(
              title,
              fontSize: 15,
              color: AppColors.buttonText,
              outlineColor: AppColors.woodDeep,
              outlineWidth: 2.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GameBackButton(
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
          ),
        ),
        GameButtonLabel(
          AppLocalizations.of(context).activityStatsTitle,
          fontSize: 20,
          color: AppColors.woodDeep,
          outlineColor: AppColors.authCard,
          outlineWidth: 4,
        ),
      ],
    );
  }
}

class _MainTabBar extends StatelessWidget {
  const _MainTabBar({
    required this.activeTab,
    required this.cardColor,
    required this.borderColor,
    required this.primary,
    required this.onPrimary,
    required this.mutedForeground,
    required this.onChanged,
  });

  final _MainTab activeTab;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color onPrimary;
  final Color mutedForeground;
  final ValueChanged<_MainTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameDualBottomTabs(
      firstLabel: l10n.activityStatsStats,
      secondLabel: l10n.activityStatsHistory,
      firstSelected: activeTab == _MainTab.stats,
      onFirstTap: () => onChanged(_MainTab.stats),
      onSecondTap: () => onChanged(_MainTab.history),
    );
  }
}

class _MainTabButton extends StatelessWidget {
  const _MainTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.primary,
    required this.onPrimary,
    required this.mutedForeground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color primary;
  final Color onPrimary;
  final Color mutedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon,
                size: 18,
                color: isActive ? onPrimary : mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? onPrimary : mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.timeRange,
    required this.muted,
    required this.cardColor,
    required this.borderColor,
    required this.mutedForeground,
    required this.foreground,
    required this.onChanged,
  });

  final ActivityTimeRange timeRange;
  final Color muted;
  final Color cardColor;
  final Color borderColor;
  final Color mutedForeground;
  final Color foreground;
  final ValueChanged<ActivityTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood, width: 1.5),
      ),
      child: Row(
        children: ActivityTimeRange.values
            .where((range) => range != ActivityTimeRange.monthly)
            .map((range) {
              final isActive = timeRange == range;
              final label = switch (range) {
                ActivityTimeRange.daily => AppLocalizations.of(
                  context,
                ).activityStatsDaily,
                ActivityTimeRange.weekly => AppLocalizations.of(
                  context,
                ).activityStatsWeekly,
                ActivityTimeRange.monthly => AppLocalizations.of(
                  context,
                ).activityStatsMonthly,
              };

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.buttonGreen
                          : AppColors.parchment,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(color: AppColors.woodDeep, width: 1.5)
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.buttonText
                            : AppColors.woodDeep,
                        shadows: isActive
                            ? const [
                                Shadow(
                                  color: AppColors.woodDeep,
                                  blurRadius: 1.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

class _StepsBarChart extends StatelessWidget {
  const _StepsBarChart({
    required this.data,
    required this.goal,
    required this.timeRange,
    required this.l10n,
    required this.primary,
    required this.muted,
    required this.mutedForeground,
    required this.borderColor,
    required this.barWidth,
  });

  final List<StepChartPoint> data;
  final int goal;
  final ActivityTimeRange timeRange;
  final AppLocalizations l10n;
  final Color primary;
  final Color muted;
  final Color mutedForeground;
  final Color borderColor;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final maxY = data
        .map((e) => e.steps.toDouble())
        .fold<double>(goal.toDouble(), (prev, v) => v > prev ? v : prev);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (index) {
                    final value = maxY - (maxY * index / 4);
                    return Text(
                      _compactNumber(value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mutedForeground,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (_) {
                        return Container(
                          height: 1,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: data.map((point) {
                          final reached = point.steps >= goal;
                          final heightFactor = maxY <= 0
                              ? 0.0
                              : (point.steps / maxY).clamp(0.0, 1.0);

                          return Tooltip(
                            message:
                                '${formatStepCount(point.steps)} ${l10n.activityStatsStepsUnit}',
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: barWidth,
                                decoration: BoxDecoration(
                                  color: reached ? primary : muted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data.map((point) {
              return Expanded(
                child: Text(
                  _localizedLabel(point.label),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedForeground,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _compactNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    }
    return value.toInt().toString();
  }

  String _localizedLabel(String label) {
    if (timeRange != ActivityTimeRange.monthly || !label.startsWith('W')) {
      return label;
    }

    final week = int.tryParse(label.substring(1));
    if (week == null) return label;
    return l10n.activityStatsWeekBucket(week);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
              children: [
                TextSpan(text: value),
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.cardColor,
    required this.borderColor,
    required this.primary,
    required this.muted,
    required this.mutedForeground,
    required this.foreground,
    required this.l10n,
  });

  final StepHistoryItem item;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color muted;
  final Color mutedForeground;
  final Color foreground;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: mutedForeground,
                ),
              ),
              if (item.isGoalReached)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.activityStatsGoalReached,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatStepCount(item.steps),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${formatStepCount(item.goal)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.goal <= 0
                  ? 0
                  : (item.steps / item.goal).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: muted,
              color: item.isGoalReached ? primary : Colors.amber.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    required this.primary,
  });

  final String message;
  final VoidCallback onRetry;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.authCard.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.wood, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.woodDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
