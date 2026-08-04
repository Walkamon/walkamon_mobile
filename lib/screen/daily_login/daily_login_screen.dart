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
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_notification_dialog.dart';

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
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null &&
                provider.calendarData == null) {
              return Center(
                child: Text(
                  '${l10n.errorPrefix}: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = provider.calendarData;
            if (data == null) {
              return Center(child: Text(l10n.dailyLoginNoData));
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
                        color: AppColors.woodDeep,
                        outlineColor: AppColors.authCard,
                        outlineWidth: 4,
                      ),
                      const SizedBox(width: GameBackButton.buttonSize),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Main Gift Icon & Text
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.authCard.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.wood, width: 2),
                    ),
                    child: Center(
                      child: Image.asset(
                        AppAssets.iconDailyRewardSystem,
                        width: 62,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GameButtonLabel(
                    l10n.dailyLoginRewardTitle,
                    fontSize: 22,
                    color: AppColors.woodDeep,
                    outlineColor: AppColors.authCard,
                    outlineWidth: 4,
                  ),
                  const SizedBox(height: 12),
                  GameButtonLabel(
                    l10n.dailyLoginRewardSubtitle,
                    fontSize: 14,
                    color: AppColors.oliveDeep,
                    outlineColor: AppColors.authCard,
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
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    barrierColor: Colors.black.withValues(
                                      alpha: 0.45,
                                    ),
                                    builder: (dialogContext) {
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
                                              color: AppColors.authCard,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              border: Border.all(
                                                color: AppColors.woodDeep,
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
                                                  color: AppColors.woodDeep,
                                                  outlineColor:
                                                      AppColors.creamLight,
                                                  outlineWidth: 3,
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  l10n.dailyLoginSuccessMessage(
                                                    result.claimedDay,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: AppColors.inkBrown,
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
                                                    color: AppColors.creamLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors
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
                                                              style: const TextStyle(
                                                                color: AppColors
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
                                                              style: const TextStyle(
                                                                color: AppColors
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
                                      '${l10n.errorPrefix}: ${provider.errorMessage}',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !data.canClaimToday
                              ? AppColors.panelMuted
                              : AppColors.buttonGreen,
                          disabledBackgroundColor: AppColors.panelMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                            side: const BorderSide(
                              color: AppColors.buttonBorder,
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
                                color: AppColors.buttonText,
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
