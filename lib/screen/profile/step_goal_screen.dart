import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/constants/app_assets.dart';
import '../../core/audio/app_audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/step_goal_response.dart';
import '../../data/repositories/step_goal_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/game_notification_dialog.dart';
import 'activity_stats_screen.dart' show formatStepCount;

class StepGoalScreen extends StatefulWidget {
  const StepGoalScreen({super.key});

  @override
  State<StepGoalScreen> createState() => _StepGoalScreenState();
}

class _StepGoalScreenState extends State<StepGoalScreen> {
  static const int _minimumGoalSteps = 501;
  static const int _maximumGoalSteps = 100000;

  final StepGoalRepository _repository = StepGoalRepository();
  final List<int> _presets = const [5000, 8000, 10000, 15000, 20000];

  GoalProgressResponse? _progress;
  CurrentStreakResponse? _currentStreak;
  LongestStreakResponse? _longestStreak;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isClaiming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      GoalProgressResponse progress;
      try {
        progress = await _repository.getProgress();
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (!message.contains('not found') &&
            !message.contains('không tìm thấy')) {
          rethrow;
        }

        progress = GoalProgressResponse(
          targetSteps: 0,
          currentSteps: 0,
          remainingSteps: 0,
          progressPercent: 0,
          completed: false,
        );
      }

      final streakResults = await Future.wait<Object>([
        _repository.getCurrentStreak(),
        _repository.getLongestStreak(),
      ]);
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _currentStreak = streakResults[0] as CurrentStreakResponse;
        _longestStreak = streakResults[1] as LongestStreakResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;

    AppAudioService.instance.suppressNextTabSound();
    setState(() => _isClaiming = true);

    try {
      final reward = await _repository.claimReward();
      if (!mounted) return;

      unawaited(AppAudioService.instance.playReward());

      final gameState = context.read<GameStateProvider>();
      final user = gameState.user;
      if (user != null) {
        gameState.setUser(user.copyWith(coins: reward.balance));
      }

      _showMessage(
        AppLocalizations.of(
          context,
        ).stepGoalClaimSuccess(formatStepCount(reward.reward)),
        isSuccess: true,
      );
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _saveGoal(int targetSteps) async {
    final currentTarget = _progress?.targetSteps ?? 0;
    if (targetSteps < _minimumGoalSteps) {
      _showMessage(AppLocalizations.of(context).stepGoalMinError);
      return;
    }

    if (targetSteps > _maximumGoalSteps) {
      _showMessage(AppLocalizations.of(context).stepGoalMaxError);
      return;
    }

    if (currentTarget > 0 && targetSteps <= currentTarget) {
      _showMessage(AppLocalizations.of(context).stepGoalGreaterThanCurrent);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _repository.setGoal(targetSteps);
      await _loadProgress();
      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(
          context,
        ).stepGoalSaved(formatStepCount(targetSteps)),
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyGoalError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _friendlyGoalError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '');
    final lower = message.toLowerCase();

    if (lower.contains('required') || lower.contains('greater than 500')) {
      return AppLocalizations.of(context).stepGoalMinError;
    }

    if (lower.contains('cannot exceed 100000')) {
      return AppLocalizations.of(context).stepGoalMaxError;
    }

    if (lower.contains('greater than the current target')) {
      return AppLocalizations.of(context).stepGoalGreaterThanCurrent;
    }

    return message;
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showGameNotificationDialog(
      context,
      message: message,
      isSuccess: isSuccess,
    );
  }

  Future<void> _showCustomGoalSheet() async {
    if (_isSaving || !mounted) return;

    final controller = TextEditingController();
    final focusNode = FocusNode();
    final formKey = GlobalKey<FormState>();
    var isClosing = false;

    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = theme.colorScheme.surface;
        final primary = theme.colorScheme.primary;
        final borderColor = isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder;
        final mutedForeground = isDark
            ? AppColors.darkMutedForeground
            : AppColors.lightMutedForeground;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AppIcon(Icons.tune_rounded, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.stepGoalCustomTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (isClosing) return;
                          isClosing = true;
                          focusNode.unfocus();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 100),
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        icon: const AppIcon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: l10n.stepGoalInputHint,
                      suffixText: l10n.activityStatsStepsPerDay,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) {
                        return l10n.stepGoalInvalidNumber;
                      }
                      if (parsed < _minimumGoalSteps) {
                        return l10n.stepGoalMinError;
                      }
                      if (parsed > _maximumGoalSteps) {
                        return l10n.stepGoalMaxError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (isClosing) return;
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            isClosing = true;
                            final target = int.parse(controller.text);
                            focusNode.unfocus();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(target);
                            }
                          },
                          child: Text(l10n.profileEditConfirm),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (isClosing) return;
                            isClosing = true;
                            focusNode.unfocus();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: Text(
                            l10n.friendsCancel,
                            style: TextStyle(color: mutedForeground),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;
    controller.dispose();
    focusNode.dispose();
    if (value != null && mounted) await _saveGoal(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              _Header(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: _buildBody(
                    cardColor: cardColor,
                    primary: primary,
                    muted: muted,
                    mutedForeground: mutedForeground,
                    borderColor: borderColor,
                    foreground: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required Color cardColor,
    required Color primary,
    required Color muted,
    required Color mutedForeground,
    required Color borderColor,
    required Color foreground,
  }) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(child: CircularProgressIndicator(color: primary)),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _ErrorState(
              message: _error!,
              primary: primary,
              onRetry: _loadProgress,
            ),
          ),
        ],
      );
    }

    final progress = _progress!;
    final currentStreak = _currentStreak?.currentStreak ?? 0;
    final longestStreak = _longestStreak?.longestStreak ?? 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        _ProgressCard(
          progress: progress,
          cardColor: cardColor,
          primary: primary,
          muted: muted,
          mutedForeground: mutedForeground,
          borderColor: borderColor,
          foreground: foreground,
        ),
        const SizedBox(height: 16),
        _StreakRewardCard(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          isClaiming: _isClaiming,
          cardColor: cardColor,
          primary: primary,
          muted: muted,
          mutedForeground: mutedForeground,
          borderColor: borderColor,
          foreground: foreground,
          onClaim: _claimReward,
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context).stepGoalSuggestions,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _presets.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 82,
          ),
          itemBuilder: (context, index) {
            if (index == _presets.length) {
              return _CustomGoalButton(
                enabled: !_isSaving,
                cardColor: cardColor,
                borderColor: borderColor,
                mutedForeground: mutedForeground,
                onTap: _showCustomGoalSheet,
              );
            }

            final preset = _presets[index];
            return _PresetGoalButton(
              steps: preset,
              selected: progress.targetSteps == preset,
              enabled: !_isSaving,
              cardColor: cardColor,
              borderColor: borderColor,
              primary: primary,
              foreground: foreground,
              mutedForeground: mutedForeground,
              onTap: () => _saveGoal(preset),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: cardColor,
            shape: CircleBorder(side: BorderSide(color: borderColor)),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: AppIcon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: mutedForeground,
                ),
              ),
            ),
          ),
        ),
        Text(
          AppLocalizations.of(context).stepGoalTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.cardColor,
    required this.primary,
    required this.muted,
    required this.mutedForeground,
    required this.borderColor,
    required this.foreground,
  });

  final GoalProgressResponse progress;
  final Color cardColor;
  final Color primary;
  final Color muted;
  final Color mutedForeground;
  final Color borderColor;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final hasGoal = progress.targetSteps > 0;
    final l10n = AppLocalizations.of(context);
    final value = (progress.progressPercent / 100).clamp(0.0, 1.0);
    final completedColor = Colors.green.shade500;
    final activeColor = progress.completed ? completedColor : primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: muted,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withValues(alpha: 0.4)),
            ),
            child: AppIcon(
              Icons.directions_walk_rounded,
              color: primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.stepGoalTodayProgress,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: mutedForeground,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatStepCount(progress.currentSteps),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                  TextSpan(
                    text: hasGoal
                        ? l10n.stepGoalOutOfSteps(
                            formatStepCount(progress.targetSteps),
                          )
                        : ' ${l10n.activityStatsStepsUnit}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 12,
                  backgroundColor: muted,
                  color: activeColor,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${progress.progressPercent.toStringAsFixed(progress.progressPercent % 1 == 0 ? 0 : 1)}%',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (progress.completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: completedColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.activityStatsGoalReached,
                    style: TextStyle(
                      color: completedColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                Text(
                  hasGoal
                      ? l10n.stepGoalRemaining(
                          formatStepCount(progress.remainingSteps),
                        )
                      : l10n.stepGoalNotSet,
                  style: TextStyle(
                    color: mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            !hasGoal
                ? l10n.stepGoalChoosePrompt
                : progress.completed
                ? l10n.stepGoalCompletedMessage
                : l10n.stepGoalActiveMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetGoalButton extends StatelessWidget {
  const _PresetGoalButton({
    required this.steps,
    required this.selected,
    required this.enabled,
    required this.cardColor,
    required this.borderColor,
    required this.primary,
    required this.foreground,
    required this.mutedForeground,
    required this.onTap,
  });

  final int steps;
  final bool selected;
  final bool enabled;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color foreground;
  final Color mutedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatStepCount(steps),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: selected ? primary : foreground.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).activityStatsStepsPerDay,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? primary.withValues(alpha: 0.8)
                    : mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakRewardCard extends StatelessWidget {
  const _StreakRewardCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.isClaiming,
    required this.cardColor,
    required this.primary,
    required this.muted,
    required this.mutedForeground,
    required this.borderColor,
    required this.foreground,
    required this.onClaim,
  });

  final int currentStreak;
  final int longestStreak;
  final bool isClaiming;
  final Color cardColor;
  final Color primary;
  final Color muted;
  final Color mutedForeground;
  final Color borderColor;
  final Color foreground;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final reward = currentStreak * 10;
    final canClaim = currentStreak > 0;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  Icons.local_fire_department_rounded,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stepGoalStreakTitle,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.stepGoalStreakSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StreakMetric(
                  label: l10n.streakCurrent,
                  value: '$currentStreak ${l10n.streakDays}',
                  muted: muted,
                  foreground: foreground,
                  mutedForeground: mutedForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakMetric(
                  label: l10n.stepGoalLongest,
                  value: '$longestStreak ${l10n.streakDays}',
                  muted: muted,
                  foreground: foreground,
                  mutedForeground: mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '+${formatStepCount(reward)}',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.shopCurrency}',
                        style: TextStyle(
                          color: mutedForeground,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: canClaim && !isClaiming ? onClaim : null,
                icon: isClaiming
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const AppIcon(
                        Icons.wallet_giftcard_rounded,
                        asset: AppAssets.iconClaimReward,
                        size: 18,
                      ),
                label: Text(
                  isClaiming ? l10n.stepGoalClaiming : l10n.missionsClaim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.label,
    required this.value,
    required this.muted,
    required this.foreground,
    required this.mutedForeground,
  });

  final String label;
  final String value;
  final Color muted;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mutedForeground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomGoalButton extends StatelessWidget {
  const _CustomGoalButton({
    required this.enabled,
    required this.cardColor,
    required this.borderColor,
    required this.mutedForeground,
    required this.onTap,
  });

  final bool enabled;
  final Color cardColor;
  final Color borderColor;
  final Color mutedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(Icons.tune_rounded, color: mutedForeground, size: 20),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).stepGoalCustomShort,
              style: TextStyle(
                color: mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.primary,
    required this.onRetry,
  });

  final String message;
  final Color primary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(Icons.flag_outlined, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              AppLocalizations.of(context).retry,
              style: TextStyle(color: primary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
