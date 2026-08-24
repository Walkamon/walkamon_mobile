import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/step_goal_response.dart';
import '../../data/repositories/step_goal_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/game_async_state.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final StepGoalRepository _repository = StepGoalRepository();

  CurrentStreakResponse? _currentStreak;
  LongestStreakResponse? _longestStreak;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getCurrentStreak(),
        _repository.getLongestStreak(),
      ]);

      if (!mounted) return;
      setState(() {
        _currentStreak = results[0] as CurrentStreakResponse;
        _longestStreak = results[1] as LongestStreakResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).streakLoadFailed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final currentStreak = _currentStreak?.currentStreak ?? 0;
    final longestStreak = _longestStreak?.longestStreak ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: GameButtonLabel(
          l10n.streakTitle,
          fontSize: 20,
          color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
          outlineColor: isDark ? AppColors.darkTextOutline : AppColors.authCard,
          outlineWidth: 4,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: GameBackButton(
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: GameLoadingIndicator(label: l10n.loading))
          : _errorMessage != null
          ? GameAsyncStatePanel(
              message: _errorMessage!,
              isError: true,
              onRetry: _loadStreakData,
              retryLabel: l10n.retry,
            )
          : RefreshIndicator(
              onRefresh: _loadStreakData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildCurrentStreakCard(colorScheme, currentStreak, l10n),
                  const SizedBox(height: 16),
                  _buildMilestoneCard(colorScheme, currentStreak, l10n),
                  const SizedBox(height: 16),
                  _buildStatsGrid(
                    colorScheme,
                    currentStreak,
                    longestStreak,
                    l10n,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStreakCard(
    ColorScheme colorScheme,
    int currentStreak,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.wood,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: AppIcon(
              Icons.local_fire_department_rounded,
              asset: AppAssets.iconStreak,
              size: 76,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$currentStreak',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkForeground
                  : AppColors.woodDeep,
            ),
          ),
          Text(
            l10n.streakDays,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkForeground
                  : AppColors.oliveDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.streakEncouragement,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkMutedForeground
                  : AppColors.outlineBrown,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(
    ColorScheme colorScheme,
    int currentStreak,
    AppLocalizations l10n,
  ) {
    final progress = (currentStreak / 30).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.wood,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: AppIcon(
              Icons.card_giftcard_rounded,
              asset: AppAssets.iconRewardChest,
              color: AppColors.gold,
              size: 42,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakThirtyDays,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.brightness == Brightness.dark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.parchment,
                    color: AppColors.buttonGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currentStreak/30',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.brightness == Brightness.dark
                        ? AppColors.darkMutedForeground
                        : AppColors.outlineBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    ColorScheme colorScheme,
    int currentStreak,
    int longestStreak,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            colorScheme,
            icon: Icons.emoji_events_rounded,
            title: l10n.streakRecord,
            value: '$longestStreak ${l10n.streakDays}',
            accent: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            colorScheme,
            icon: Icons.calendar_today_rounded,
            title: l10n.streakCurrent,
            value: '$currentStreak ${l10n.streakDays}',
            accent: AppColors.buttonGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.wood,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkMuted
                  : AppColors.creamLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.wood,
                width: 1.2,
              ),
            ),
            child: AppIcon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkMutedForeground
                  : AppColors.outlineBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.brightness == Brightness.dark
                  ? AppColors.darkForeground
                  : AppColors.woodDeep,
            ),
          ),
        ],
      ),
    );
  }
}
