import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/google_icon.dart';
import '../../widgets/settings_toggle.dart';
import '../../widgets/sprout_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark ? AppColors.darkForeground : AppColors.lightForeground;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: IconButton(
                      onPressed: () => setState(() => _showSettings = true),
                      icon: Icon(
                        Icons.explore_outlined,
                        size: 28,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(),
                        _AnimatedFadeSlide(
                          delay: Duration.zero,
                          child: Column(
                            children: [
                              const SproutLogo(size: 96),
                              const SizedBox(height: 24),
                              Text(
                                'Walkamon',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Walk & Grow Together',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        _AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 200),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Column(
                              children: [
                                _PrimaryButton(
                                  label: 'Khám Phá Ngay',
                                  backgroundColor: primary,
                                  foregroundColor: onPrimary,
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/story'),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _OutlineButton(
                                        label: 'Đăng Nhập',
                                        color: primary,
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          '/auth/login',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _OutlineButton(
                                        label: 'Đăng Ký',
                                        color: primary,
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          '/auth/register',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: muted,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'HOẶC',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: mutedForeground,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _GoogleButton(
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  foregroundColor: foreground,
                                  mutedColor: muted,
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/home'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSettings)
            _SettingsOverlay(
              onClose: () => setState(() => _showSettings = false),
              cardColor: cardColor,
              borderColor: borderColor,
              foregroundColor: foreground,
              mutedForeground: mutedForeground,
              primary: primary,
            ),
        ],
      ),
    );
  }
}

class _AnimatedFadeSlide extends StatefulWidget {
  const _AnimatedFadeSlide({
    required this.child,
    required this.delay,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.cardColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.mutedColor,
    required this.onPressed,
  });

  final Color cardColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color mutedColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: borderColor, width: 2),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          hoverColor: mutedColor.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleIcon(),
                const SizedBox(width: 12),
                Text(
                  'Đăng nhập bằng Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsOverlay extends StatelessWidget {
  const _SettingsOverlay({
    required this.onClose,
    required this.cardColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.mutedForeground,
    required this.primary,
  });

  final VoidCallback onClose;
  final Color cardColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color mutedForeground;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Consumer<GameStateProvider>(
                  builder: (context, gameState, _) {
                    final settings = gameState.settings;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tùy Chỉnh',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: foregroundColor,
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: Icon(
                                Icons.close,
                                color: mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Chế độ tối',
                          mutedForeground: mutedForeground,
                          foregroundColor: foregroundColor,
                          toggle: SettingsToggle(
                            active: settings.darkMode,
                            onChanged: () => gameState.updateSettings(
                              darkMode: !settings.darkMode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SettingsRow(
                          icon: Icons.volume_up_outlined,
                          label: 'Âm thanh',
                          mutedForeground: mutedForeground,
                          foregroundColor: foregroundColor,
                          toggle: SettingsToggle(
                            active: settings.soundEnabled,
                            onChanged: () => gameState.updateSettings(
                              soundEnabled: !settings.soundEnabled,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.mutedForeground,
    required this.foregroundColor,
    required this.toggle,
  });

  final IconData icon;
  final String label;
  final Color mutedForeground;
  final Color foregroundColor;
  final Widget toggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: mutedForeground),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ],
        ),
        toggle,
      ],
    );
  }
}
