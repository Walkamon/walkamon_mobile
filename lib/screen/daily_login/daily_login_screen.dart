import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import '../../providers/daily_login_provider.dart';
import '../../providers/game_state_provider.dart';
import 'widgets/daily_login_calendar_widget.dart';
import 'package:walkamon_mobile/data/models/daily_login_model.dart';
import '../../core/audio/app_audio_service.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/feedback/app_haptics.dart';
import '../../core/localization/translation_resolver.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_async_state.dart';

class DailyLoginScreen extends StatefulWidget {
  const DailyLoginScreen({super.key});

  @override
  State<DailyLoginScreen> createState() => _DailyLoginScreenState();
}

class _DailyLoginScreenState extends State<DailyLoginScreen> {
  bool _isNoticeVisible = false;
  Timer? _noticeTimer;

  void _showDailyNotice(String message) {
    if (!mounted || _isNoticeVisible) return;

    _isNoticeVisible = true;
    showGameNotificationDialog(context, message: message, isSuccess: false);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(milliseconds: 1100), () {
      _isNoticeVisible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyLoginProvider>().loadDailyLoginStatus();
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<DailyLoginProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.calendarData == null) {
              return Center(child: GameLoadingIndicator(label: l10n.loading));
            }

            if (provider.errorMessage != null &&
                provider.calendarData == null) {
              return GameAsyncStatePanel(
                message: provider.failure == null
                    ? l10n.apiErrorUnexpectedResponse
                    : TranslationResolver.resolveFailure(
                        context,
                        provider.failure!,
                      ),
                isError: true,
                onRetry: provider.loadDailyLoginStatus,
                retryLabel: l10n.retry,
              );
            }

            final data = provider.calendarData;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (data == null) {
              return GameAsyncStatePanel(
                message: l10n.dailyLoginNoData,
                onRetry: provider.loadDailyLoginStatus,
                retryLabel: l10n.retry,
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  // Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GameBackButton(
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      GameButtonLabel(
                        l10n.dailyLoginTitle,
                        fontSize: 20,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.woodDeep,
                        outlineColor: isDark
                            ? AppColors.darkTextOutline
                            : AppColors.authCard,
                        outlineWidth: 4,
                      ),
                      const SizedBox(width: GameBackButton.buttonSize),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Main Gift Icon & Text
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: Image.asset(
                      AppAssets.iconDailyRewardSystem,
                      width: 78,
                      height: 78,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GameButtonLabel(
                    l10n.dailyLoginRewardTitle,
                    fontSize: 22,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                    outlineColor: isDark
                        ? AppColors.darkTextOutline
                        : AppColors.authCard,
                    outlineWidth: 4,
                  ),
                  const SizedBox(height: 12),
                  GameButtonLabel(
                    l10n.dailyLoginRewardSubtitle,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.oliveDeep,
                    outlineColor: isDark
                        ? AppColors.darkTextOutline
                        : AppColors.authCard,
                    outlineWidth: 3.5,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 26),

                  // Lưới Lịch điểm danh (Calendar)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: DailyLoginCalendarWidget(
                            rewards: data.rewards,
                            currentDay: data.currentDay,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Claim Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: provider.isLoading || !data.canClaimToday
                            ? null
                            : () async {
                                // Xác định rõ kiểu dữ liệu trả về để compiler không nhận nhầm thành bool
                                AppAudioService.instance.suppressNextTabSound();
                                final ClaimDailyRewardData? result =
                                    await provider.claimReward();

                                if (result != null && context.mounted) {
                                  final gameState = context
                                      .read<GameStateProvider>();
                                  final user = gameState.user;
                                  if (user != null) {
                                    gameState.setUser(
                                      user.copyWith(coins: result.balance),
                                    );
                                  }
                                  unawaited(
                                    AppAudioService.instance.playReward(),
                                  );
                                  unawaited(AppHaptics.success());
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    barrierColor: Colors.black.withValues(
                                      alpha: 0.45,
                                    ),
                                    builder: (dialogContext) {
                                      final isDark =
                                          Theme.of(dialogContext).brightness ==
                                          Brightness.dark;
                                      return Dialog(
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 24,
                                            ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 390,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              26,
                                              24,
                                              22,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkCard
                                                  : AppColors.authCard,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.woodDeep,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.24),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GameButtonLabel(
                                                  l10n.dailyLoginSuccessTitle,
                                                  fontSize: 24,
                                                  color: isDark
                                                      ? AppColors.darkForeground
                                                      : AppColors.woodDeep,
                                                  outlineColor: isDark
                                                      ? AppColors
                                                            .darkTextOutline
                                                      : AppColors.creamLight,
                                                  outlineWidth: 3,
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  l10n.dailyLoginSuccessMessage(
                                                    result.claimedDay,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors
                                                              .darkForeground
                                                        : AppColors.inkBrown,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppColors.darkMuted
                                                        : AppColors.creamLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppColors.darkBorder
                                                          : AppColors
                                                                .outlineBrown,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Image.asset(
                                                        AppAssets.iconDewDrop,
                                                        width: 42,
                                                        height: 42,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              l10n.dailyLoginSuccessReward(
                                                                result.reward,
                                                              ),
                                                              style: TextStyle(
                                                                color: isDark
                                                                    ? AppColors
                                                                          .darkForeground
                                                                    : AppColors
                                                                          .woodDeep,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              l10n.dailyLoginSuccessBalance(
                                                                result.balance,
                                                              ),
                                                              style: TextStyle(
                                                                color: isDark
                                                                    ? AppColors
                                                                          .darkMutedForeground
                                                                    : AppColors
                                                                          .outlineBrown,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 22),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(),
                                                    child: GameButtonLabel(
                                                      l10n.dailyLoginSuccessAction,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  if (mounted &&
                                      provider.errorMessage != null) {
                                    _showDailyNotice(
                                      provider.failure == null
                                          ? l10n.apiErrorUnexpectedResponse
                                          : TranslationResolver.resolveFailure(
                                              context,
                                              provider.failure!,
                                            ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !data.canClaimToday
                              ? (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.panelMuted)
                              : (isDark
                                    ? AppColors.darkLife
                                    : AppColors.buttonGreen),
                          disabledBackgroundColor: isDark
                              ? AppColors.darkMuted
                              : AppColors.panelMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.buttonBorder,
                              width: 2,
                            ),
                          ),
                          elevation: !data.canClaimToday ? 0 : 2,
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : GameButtonLabel(
                                !data.canClaimToday
                                    ? l10n.dailyLoginClaimedToday
                                    : l10n.dailyLoginClaimNow,
                                fontSize: 17,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.buttonText,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
