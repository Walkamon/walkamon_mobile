import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/constants/app_assets.dart';
import '../../data/models/step_goal_response.dart';
import '../../data/repositories/step_goal_repository.dart';
import '../../l10n/app_localizations.dart';

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
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final currentStreak = _currentStreak?.currentStreak ?? 0;
    final longestStreak = _longestStreak?.longestStreak ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.streakTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
            ),
            child: AppIcon(
              Icons.local_fire_department_rounded,
              asset: AppAssets.iconStreak,
              size: 42,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$currentStreak',
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          ),
          Text(
            l10n.streakDays,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.streakEncouragement,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppIcon(
              Icons.card_giftcard_rounded,
              asset: AppAssets.iconRewardChest,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakThirtyDays,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currentStreak/30',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
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
            accent: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            colorScheme,
            icon: Icons.calendar_today_rounded,
            title: l10n.streakCurrent,
            value: '$currentStreak ${l10n.streakDays}',
            accent: colorScheme.primary,
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
