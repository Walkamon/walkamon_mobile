import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    await context.read<GameStateProvider>().logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final accentForeground = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tài khoản & Bảo mật',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                  onPressed: () =>
                      Navigator.pushNamed(context, '/auth/change-password'),
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
            ],
          ),
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
    this.isWarning = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
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
