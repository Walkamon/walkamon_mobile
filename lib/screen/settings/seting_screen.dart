import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

import '../../core/l10n/locale_helper.dart';
import '../../core/constants/app_assets.dart';

import '../../core/theme/app_colors.dart';

import '../../core/utils/sendfeedback_screen_error_translator.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/game_back_button.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_notification_dialog.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isLoggingOut = false;
  bool _showFeedbackPopup = false;
  bool _isSendingFeedback = false;
  String _feedbackType = 'suggestion';
  String _feedbackText = '';
  bool _feedbackSentSuccess = false;
  String? _feedbackMessage;
  String? _tutorialAccountKey;

  bool get _isFeedbackValid => _feedbackText.trim().length >= 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountKey = context.read<GameStateProvider>().user?.id.trim();
    if (accountKey == null ||
        accountKey.isEmpty ||
        accountKey == _tutorialAccountKey) {
      return;
    }
    _tutorialAccountKey = accountKey;
    context.read<TutorialProvider>().synchronizeAccount(accountKey);
  }

  Future<void> _replayTutorial({required bool pvp}) async {
    final tutorial = context.read<TutorialProvider>();
    if (pvp) {
      await tutorial.replayPvp();
    } else {
      await tutorial.replayHome();
    }
    if (!mounted) return;
    Navigator.pushNamed(context, pvp ? '/pvp' : '/home');
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await context.read<StepTrackingProvider>().stopForUser();
    await context.read<GameStateProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _handleSendFeedback() async {
    if (_isSendingFeedback) return;

    if (!_isFeedbackValid) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _feedbackMessage = l10n.feedbackMinLength(_feedbackText.trim().length);
      });
      return;
    }

    setState(() => _isSendingFeedback = true);

    final feedbackTypeCode = _feedbackType == 'bug'
        ? 'bug_report'
        : 'suggestion';

    final result = await context
        .read<GameStateProvider>()
        .sendFeedbackWithCooldown(
          content: _feedbackText.trim(),
          feedbackTypeCode: feedbackTypeCode,
        );

    if (!mounted) return;
    setState(() {
      _isSendingFeedback = false;
    });

    // Show errors or cooldown messages inside the popup instead of SnackBar
    if (result.retryAfter != null) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _feedbackMessage = translateSendFeedbackError(
          result.message ?? l10n.feedbackWaitBeforeRetry,
        );
      });
      return;
    }

    if (result.success) {
      setState(() {
        _feedbackSentSuccess = true;
        _feedbackMessage = null;
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _showFeedbackPopup = false;
          _feedbackText = '';
          _feedbackType = 'suggestion';
          _feedbackSentSuccess = false;
          _feedbackMessage = null;
        });
      });
    } else {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _feedbackMessage = translateSendFeedbackError(
          result.message ?? l10n.feedbackSendFailed,
        );
      });
    }
  }

  void _toggleLanguage() {
    final settings = context.read<GameStateProvider>().settings;
    final nextLanguage = LocaleHelper.isVietnamese(settings.languageCode)
        ? 'en-US'
        : 'vi-VN';
    context.read<GameStateProvider>().setLanguageCode(nextLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final l10n = AppLocalizations.of(context);
    final isVi = LocaleHelper.isVietnamese(gameState.settings.languageCode);
    final languageLabel = isVi ? l10n.languageVi : l10n.languageEn;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final outlineColor = isDark ? AppColors.darkBorder : AppColors.authCard;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GameBackButton(
                          semanticLabel: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/home'),
                        ),
                        GameButtonLabel(
                          l10n.gameSettings,
                          fontSize: 20,
                          color: textColor,
                          outlineColor: outlineColor,
                          outlineWidth: 4,
                        ),
                        const SizedBox(width: GameBackButton.buttonSize),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ================= KHỐI 1: THÊM MỚI HỆ THỐNG =================
                    GameButtonLabel(
                      l10n.system,
                      fontSize: 17,
                      color: textColor,
                      outlineColor: outlineColor,
                      outlineWidth: 3.5,
                    ),
                    const SizedBox(height: 18),

                    _SettingsPanel(
                      child: Column(
                        children: [
                          _SettingsSwitch(
                            label: l10n.bgm,
                            icon: Icons.music_note_rounded,
                            asset: AppAssets.iconMusic,
                            value: gameState.settings.backgroundMusicEnabled,
                            onChanged: (value) => context
                                .read<GameStateProvider>()
                                .updateSettings(backgroundMusicEnabled: value),
                          ),
                          _SettingsSwitch(
                            label: l10n.sfx,
                            icon: Icons.volume_up_rounded,
                            asset: AppAssets.iconVolume,
                            value: gameState.settings.soundEnabled,
                            onChanged: (value) => context
                                .read<GameStateProvider>()
                                .updateSettings(soundEnabled: value),
                          ),
                          _SettingsSwitch(
                            label: l10n.haptics,
                            subtitle: l10n.hapticsSubtitle,
                            icon: Icons.touch_app,
                            asset: AppAssets.iconUse,
                            value: gameState.settings.hapticsEnabled,
                            onChanged: (value) => unawaited(
                              context
                                  .read<GameStateProvider>()
                                  .setHapticsEnabled(value),
                            ),
                          ),
                          _ThemeModeSetting(
                            value: gameState.settings.themeCode,
                            onChanged: (value) {
                              if (value != null)
                                context.read<GameStateProvider>().setThemeCode(
                                  value,
                                );
                            },
                          ),
                          _SettingsSwitch(
                            label: l10n.notificationsRemind,
                            subtitle: l10n.notificationsSubtitle,
                            icon: Icons.notifications_none_rounded,
                            value: gameState.settings.notifications,
                            enabled: !gameState.isUpdatingNotifications,
                            onChanged: (newValue) async {
                              final enabled = await context
                                  .read<GameStateProvider>()
                                  .setNotificationsEnabled(newValue);
                              if (!enabled && newValue && mounted) {
                                final isVietnamese =
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode ==
                                    'vi';
                                showGameNotificationDialog(
                                  context,
                                  isSuccess: false,
                                  message: isVietnamese
                                      ? 'Trình duyệt đang chặn thông báo. Hãy mở cài đặt cạnh địa chỉ trang và cho phép Thông báo, rồi bật lại công tắc.'
                                      : 'Notifications are blocked by the browser. Open the site settings beside the address bar, allow Notifications, then turn the switch on again.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    GameButtonLabel(
                      l10n.featuresSupport,
                      fontSize: 17,
                      color: textColor,
                      outlineColor: outlineColor,
                      outlineWidth: 3.5,
                    ),
                    const SizedBox(height: 18),

                    _SettingsPanel(
                      child: Column(
                        children: [
                          _SettingsButton(
                            label: l10n.language,
                            icon: Icons.language,
                            onPressed: _toggleLanguage,
                            trailing: Text(
                              languageLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.oliveDeep,
                              ),
                            ),
                          ),
                          _SettingsButton(
                            label: l10n.sendFeedback,
                            icon: Icons.message_outlined,
                            onPressed: () => setState(() {
                              _feedbackMessage = null;
                              _showFeedbackPopup = true;
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.tutorialSettingsTitle,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .6,
                                ),
                              ),
                            ),
                          ),
                          _SettingsButton(
                            label: l10n.tutorialReplayHome,
                            icon: Icons.pets_rounded,
                            onPressed: () => _replayTutorial(pvp: false),
                          ),
                          _SettingsButton(
                            label: l10n.tutorialReplayPvp,
                            icon: Icons.flag_rounded,
                            onPressed: () => _replayTutorial(pvp: true),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    GameButtonLabel(
                      l10n.accountSecurity,
                      fontSize: 17,
                      color: textColor,
                      outlineColor: outlineColor,
                      outlineWidth: 3.5,
                    ),
                    const SizedBox(height: 18),

                    _SettingsPanel(
                      child: _SettingsButton(
                        label: l10n.changePassword,
                        icon: Icons.key_rounded,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/auth/change-password',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SettingsPanel(
                      child: _SettingsButton(
                        label: l10n.logout,
                        icon: Icons.logout_rounded,
                        onPressed: _handleLogout,
                        isWarning: true,
                        isLoading: _isLoggingOut,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            if (_showFeedbackPopup) _buildFeedbackPopup(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackPopup(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final mutedColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.outlineBrown;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showFeedbackPopup = false),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 80,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.authCard,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.wood,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.woodDeep.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _feedbackSentSuccess
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const AppIcon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppColors.oliveDeep,
                          ),
                          const SizedBox(height: 12),
                          GameButtonLabel(
                            l10n.feedbackSuccess,
                            fontSize: 17,
                            color: AppColors.woodDeep,
                            outlineColor: AppColors.creamLight,
                            outlineWidth: 2.5,
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.75,
                          minWidth: 280,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GameButtonLabel(
                                    l10n.feedbackTitle,
                                    fontSize: 17,
                                    color: textColor,
                                    outlineColor: AppColors.creamLight,
                                    outlineWidth: 2.5,
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _showFeedbackPopup = false,
                                    ),
                                    icon: const AppIcon(
                                      Icons.close_rounded,
                                      size: 28,
                                      color: AppColors.woodDeep,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FeedbackTypeButton(
                                      label: l10n.feedbackSuggestion,
                                      selected: _feedbackType == 'suggestion',
                                      onTap: () => setState(
                                        () => _feedbackType = 'suggestion',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _FeedbackTypeButton(
                                      label: l10n.feedbackBug,
                                      selected: _feedbackType == 'bug',
                                      onTap: () =>
                                          setState(() => _feedbackType = 'bug'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                l10n.feedbackDetail,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                minLines: 4,
                                maxLines: 6,
                                onChanged: (value) => setState(() {
                                  _feedbackText = value;
                                  _feedbackMessage = null;
                                }),
                                decoration: InputDecoration(
                                  hintText: _feedbackType == 'suggestion'
                                      ? l10n.feedbackHintSuggestion
                                      : l10n.feedbackHintBug,
                                  hintStyle: TextStyle(
                                    color: mutedColor,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.creamLight,
                                  suffixIcon: const Padding(
                                    padding: EdgeInsets.only(
                                      right: 10,
                                      bottom: 54,
                                    ),
                                    child: AppIcon(
                                      Icons.edit_rounded,
                                      size: 23,
                                      color: AppColors.woodLight,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.wood,
                                      width: 1.8,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.wood,
                                      width: 1.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.oliveDeep,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Show backend/cooldown/validation messages only when set
                              if (_feedbackMessage != null)
                                Text(
                                  _feedbackMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _isSendingFeedback
                                    ? null
                                    : _handleSendFeedback,
                                child: GameButtonLabel(
                                  _isSendingFeedback
                                      ? l10n.feedbackSending
                                      : l10n.feedbackSubmit,
                                  fontSize: 14,
                                  color: AppColors.buttonText,
                                  outlineColor: AppColors.woodDeep,
                                  outlineWidth: 2.5,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonYellow,
                                  foregroundColor: AppColors.buttonText,
                                  shape: const StadiumBorder(
                                    side: BorderSide(
                                      color: AppColors.woodDeep,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackTypeButton extends StatelessWidget {
  const _FeedbackTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.leafLight : AppColors.creamLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.oliveDeep : AppColors.wood,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.oliveDeep : AppColors.woodDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSetting extends StatelessWidget {
  const _ThemeModeSetting({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = value == 'dark';
    final appDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appDark ? AppColors.darkNestedCard : AppColors.authCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: appDark ? AppColors.darkCardBorder : AppColors.wood,
          width: 1.35,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: appDark ? AppColors.darkMuted : AppColors.creamLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: appDark ? AppColors.darkIconBorder : AppColors.wood,
                width: 1.3,
              ),
            ),
            child: Image.asset(
              isDark ? AppAssets.iconMoon : AppAssets.iconSun,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLocalizations.of(context).darkMode,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: appDark ? AppColors.darkForeground : AppColors.woodDeep,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (enabled) => onChanged(enabled ? 'dark' : 'light'),
            activeThumbColor: appDark
                ? AppColors.darkForeground
                : AppColors.authCard,
            activeTrackColor: isDark
                ? AppColors.darkLife
                : AppColors.buttonGreen,
            inactiveThumbColor: appDark
                ? AppColors.darkForeground
                : AppColors.authCard,
            inactiveTrackColor: AppColors.creamDeep,
            trackOutlineColor: WidgetStatePropertyAll(
              appDark ? AppColors.darkBorder : AppColors.woodDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkMuted
            : AppColors.leafLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.oliveDeep,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsButton extends StatefulWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.isWarning = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Widget? trailing;
  final bool isWarning;
  final bool isLoading;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final warningColor = isDark ? AppColors.blossom : AppColors.danger;
    final buttonBackground = isDark
        ? AppColors.darkNestedCard
        : AppColors.authCard.withValues(alpha: 0.97);
    return GestureDetector(
      onTapDown: widget.isLoading
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.wood,
              width: 1.35,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: AppIcon(
                    widget.icon,
                    size: 40,
                    color: widget.isWarning
                        ? warningColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkForeground
                              : AppColors.woodDeep),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.isWarning ? warningColor : textColor,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 10),
              ],
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.oliveDeep,
                  ),
                )
              else
                AppIcon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: textColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    this.asset,
    required this.label,
    this.subtitle = '',
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String? asset;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final mutedColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.outlineBrown;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkNestedCard
            : AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.wood,
          width: 1.35,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: asset != null
                  ? Image.asset(asset!, width: 42, height: 42)
                  : AppIcon(icon, size: 40, color: textColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: isDark
                ? AppColors.darkForeground
                : AppColors.authCard,
            activeTrackColor: isDark
                ? AppColors.darkLife
                : AppColors.buttonGreen,
            inactiveThumbColor: isDark
                ? AppColors.darkForeground
                : AppColors.authCard,
            inactiveTrackColor: isDark
                ? AppColors.darkMuted
                : AppColors.creamDeep,
            trackOutlineColor: WidgetStatePropertyAll(
              isDark ? AppColors.darkBorder : AppColors.woodDeep,
            ),
          ),
        ],
      ),
    );
  }
}
