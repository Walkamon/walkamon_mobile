import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/remote/notification_datasource.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/fcm_service.dart';

import '../../core/utils/sendfeedback_screen_error_translator.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';

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

  bool get _isFeedbackValid => _feedbackText.trim().length >= 20;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      final notificationRepo = NotificationRepositoryImpl(
        datasource: NotificationDatasourceImpl(ApiClient()),
      );
      final fcmService = FCMService(notificationRepo);

      // Báo server ngừng gửi push notification trước khi xóa thông tin user
      await fcmService.deactivateToken();
    } catch (e) {
      debugPrint("Lỗi hủy FCM Token: $e");
    }

    await context.read<StepTrackingProvider>().stopForUser();
    await context.read<GameStateProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _handleSendFeedback() async {
    if (_isSendingFeedback) return;

    if (!_isFeedbackValid) {
      setState(() {
        _feedbackMessage =
            'Mô tả phải có ít nhất 20 kí tự. (${_feedbackText.trim().length}/20)';
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
      setState(() {
        _feedbackMessage = translateSendFeedbackError(
          result.message ?? 'Vui lòng đợi trước khi gửi lại.',
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
      setState(() {
        _feedbackMessage = translateSendFeedbackError(
          result.message ?? 'Gửi phản hồi thất bại. Vui lòng thử lại sau.',
        );
      });
    }
  }

  void _toggleLanguage() {
    final settings = context.read<GameStateProvider>().settings;
    final currentLanguage = settings.languageCode.toLowerCase();
    final nextLanguage = currentLanguage.startsWith('vi') ? 'en-US' : 'vi-VN';
    context.read<GameStateProvider>().setLanguageCode(nextLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    final currentLanguage = gameState.settings.languageCode.toLowerCase();
    final isVi = currentLanguage.startsWith('vi');
    final languageLabel = isVi ? 'Tiếng Việt' : 'English';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ================= KHỐI 1: THÊM MỚI HỆ THỐNG =================
                    Text(
                      'Hệ thống',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.25),
                        ),
                      ),
                      child: _SettingsSwitch(
                        label: 'Thông báo nhắc nhở',
                        subtitle: 'Nhận lịch nhắc cho thú cưng ăn, đi bộ',
                        icon: Icons.notifications_none_rounded,
                        value: gameState.settings.notifications,
                        onChanged: (newValue) {
                          context
                              .read<GameStateProvider>()
                              .setNotificationsEnabled(newValue);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Tính năng & Hỗ trợ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          _SettingsButton(
                            label: 'Ngôn ngữ (Language)',
                            icon: Icons.language,
                            onPressed: _toggleLanguage,
                            trailing: Text(
                              languageLabel,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.75),
                                  ),
                            ),
                          ),
                          const Divider(height: 1),
                          _SettingsButton(
                            label: 'Gửi góp ý & Báo lỗi cho Dev',
                            icon: Icons.message_outlined,
                            onPressed: () => setState(() {
                              _feedbackMessage = null;
                              _showFeedbackPopup = true;
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Tài khoản & Bảo mật',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.25),
                        ),
                      ),
                      child: _SettingsButton(
                        label: 'Đổi mật khẩu tài khoản',
                        icon: Icons.key_rounded,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/auth/change-password',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.25),
                        ),
                      ),
                      child: _SettingsButton(
                        label: 'Đăng xuất tài khoản',
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
              if (_showFeedbackPopup) _buildFeedbackPopup(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPopup(BuildContext context) {
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.35),
                  ),
                ),
                child: _feedbackSentSuccess
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bạn đã đánh giá thành công',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                                  Text(
                                    'Gửi phản hồi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _showFeedbackPopup = false,
                                    ),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FeedbackTypeButton(
                                      label: 'Góp ý',
                                      icon: Icons.lightbulb_outline,
                                      selected: _feedbackType == 'suggestion',
                                      onTap: () => setState(
                                        () => _feedbackType = 'suggestion',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _FeedbackTypeButton(
                                      label: 'Báo lỗi',
                                      icon: Icons.bug_report_outlined,
                                      selected: _feedbackType == 'bug',
                                      onTap: () =>
                                          setState(() => _feedbackType = 'bug'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Mô tả chi tiết',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
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
                                      ? 'Bạn có ý tưởng gì mới cho game không?'
                                      : 'Bạn đã gặp vấn đề gì trong lúc chơi?',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.55),
                                      ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.25),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.25),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Show backend/cooldown/validation messages only when set
                              if (_feedbackMessage != null)
                                Text(
                                  _feedbackMessage!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _isSendingFeedback
                                    ? null
                                    : _handleSendFeedback,
                                icon: const Icon(Icons.send_rounded),
                                label: Text(
                                  _isSendingFeedback
                                      ? 'Đang gửi...'
                                      : 'Gửi ngay',
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          color: Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isWarning
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.isWarning
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.65),
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
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
