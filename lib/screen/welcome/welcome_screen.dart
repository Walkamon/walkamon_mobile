import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/google_sign_in_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/google_icon.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showSettings = false;
  String _language = 'vi';
  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _fps60 = false;

  Future<void> _handleGoogleLogin() async {
    final provider = context.read<GameStateProvider>();

    try {
      final idToken = await GoogleSignInAuth.getIdToken();
      final success = await provider.googleLogin(idToken: idToken);

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      _showGoogleLoginError(provider.errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showGoogleLoginError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showGoogleLoginError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message?.trim().isNotEmpty == true
              ? message!.trim()
              : 'Dang nhap Google that bai.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark ? AppColors.darkForeground : AppColors.lightForeground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _TopIconButton(
                      icon: Icons.explore_outlined,
                      color: primary,
                      onPressed: () => setState(() => _showSettings = true),
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
                              const _HeroLogo(size: 144),
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
                                  onPressed: () => Navigator.pushNamed(context, '/story'),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _OutlineButton(
                                        label: 'Đăng Nhập',
                                        color: primary,
                                        onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _OutlineButton(
                                        label: 'Đăng Ký',
                                        color: primary,
                                        onPressed: () => Navigator.pushNamed(context, '/auth/register'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: Container(height: 2, color: muted)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    Expanded(child: Container(height: 2, color: muted)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _GoogleButton(
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  foregroundColor: foreground,
                                  mutedColor: muted,
                                  onPressed: _handleGoogleLogin,
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
              language: _language,
              bgmEnabled: _bgmEnabled,
              sfxEnabled: _sfxEnabled,
              fps60: _fps60,
              onLanguageChanged: (value) => setState(() => _language = value),
              onBgmChanged: (value) => setState(() => _bgmEnabled = value),
              onSfxChanged: (value) {
                setState(() => _sfxEnabled = value);
                context.read<GameStateProvider>().updateSettings(
                      soundEnabled: value,
                    );
              },
              onFps60Changed: (value) => setState(() => _fps60 = value),
              onDarkModeChanged: (value) {
                context.read<GameStateProvider>().updateSettings(
                      darkMode: value,
                    );
              },
            ),
        ],
      ),
    );
  }
}

class _AnimatedFadeSlide extends StatefulWidget {
  const _AnimatedFadeSlide({required this.child, required this.delay});

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
  Timer? _startTimer;

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

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _startTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 28, color: color),
        ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
    required this.language,
    required this.bgmEnabled,
    required this.sfxEnabled,
    required this.fps60,
    required this.onLanguageChanged,
    required this.onBgmChanged,
    required this.onSfxChanged,
    required this.onFps60Changed,
    required this.onDarkModeChanged,
  });

  final VoidCallback onClose;
  final Color cardColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color mutedForeground;
  final String language;
  final bool bgmEnabled;
  final bool sfxEnabled;
  final bool fps60;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onBgmChanged;
  final ValueChanged<bool> onSfxChanged;
  final ValueChanged<bool> onFps60Changed;
  final ValueChanged<bool> onDarkModeChanged;

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
                              'Thiết Lập Game',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: foregroundColor,
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: Icon(Icons.close, color: mutedForeground),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SettingsLanguageRow(
                          foregroundColor: foregroundColor,
                          mutedForeground: mutedForeground,
                          selectedLanguage: language,
                          onChanged: onLanguageChanged,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        _SettingsRow(
                          icon: Icons.music_note,
                          label: 'Nhạc nền (BGM)',
                          foregroundColor: foregroundColor,
                          mutedForeground: mutedForeground,
                          toggle: _Toggle(
                            active: bgmEnabled,
                            onTap: () => onBgmChanged(!bgmEnabled),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SettingsRow(
                          icon: Icons.volume_up_outlined,
                          label: 'Hiệu ứng (SFX)',
                          foregroundColor: foregroundColor,
                          mutedForeground: mutedForeground,
                          toggle: _Toggle(
                            active: sfxEnabled,
                            onTap: () => onSfxChanged(!sfxEnabled),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        _SettingsRow(
                          icon: Icons.bolt,
                          label: 'Chế độ 60 FPS',
                          foregroundColor: foregroundColor,
                          mutedForeground: mutedForeground,
                          toggle: _LabeledToggle(
                            active: fps60,
                            onTap: () => onFps60Changed(!fps60),
                            label: 'Mượt mà hơn, tốn pin hơn',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Chế độ tối',
                          foregroundColor: foregroundColor,
                          mutedForeground: mutedForeground,
                          toggle: _Toggle(
                            active: settings.darkMode,
                            onTap: () => onDarkModeChanged(!settings.darkMode),
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

class _SettingsLanguageRow extends StatelessWidget {
  const _SettingsLanguageRow({
    required this.foregroundColor,
    required this.mutedForeground,
    required this.selectedLanguage,
    required this.onChanged,
  });

  final Color foregroundColor;
  final Color mutedForeground;
  final String selectedLanguage;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isVi = selectedLanguage == 'vi';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 20, color: mutedForeground),
            const SizedBox(width: 12),
            Text(
              'Ngôn ngữ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _LanguagePill(
                label: 'VI',
                active: isVi,
                onTap: () => onChanged('vi'),
              ),
              const SizedBox(width: 4),
              _LanguagePill(
                label: 'EN',
                active: !isVi,
                onTap: () => onChanged('en'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final foreground = Theme.of(context).colorScheme.onPrimary;
    final mutedForeground = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: active ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? foreground : mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledToggle extends StatelessWidget {
  const _LabeledToggle({
    required this.active,
    required this.onTap,
    required this.label,
  });

  final bool active;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Toggle(active: active, onTap: onTap),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.mutedForeground,
    required this.toggle,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color mutedForeground;
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
                fontSize: 14,
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

class _Toggle extends StatelessWidget {
  const _Toggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLogo extends StatefulWidget {
  const _HeroLogo({required this.size});

  final double size;

  @override
  State<_HeroLogo> createState() => _HeroLogoState();
}

class _HeroLogoState extends State<_HeroLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDark ? const Color(0xFF7DB9A1) : const Color(0xFF10B981);
    final innerColor = isDark ? Colors.white : Colors.white;
    final strokeColor = isDark ? const Color(0xFF7DB9A1) : const Color(0xFF10B981);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) {
          return Transform.translate(offset: Offset(0, _bounce.value), child: child);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 0.82,
              height: widget.size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: isDark ? 0.18 : 0.15),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isDark ? 0.35 : 0.22),
                    blurRadius: 34,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _HeroLogoPainter(
                primaryColor: glowColor,
                innerColor: innerColor,
                strokeColor: strokeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroLogoPainter extends CustomPainter {
  _HeroLogoPainter({
    required this.primaryColor,
    required this.innerColor,
    required this.strokeColor,
  });

  final Color primaryColor;
  final Color innerColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final shieldPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;

    // left shield
    final leftShield = Path()
      ..moveTo(50, 84)
      ..cubicTo(16, 80, 8, 48, 21, 26)
      ..cubicTo(31, 40, 44, 62, 50, 84)
      ..close();
    canvas.drawPath(leftShield, shieldPaint);

    // right shield
    final rightShield = Path()
      ..moveTo(50, 84)
      ..cubicTo(84, 80, 92, 48, 79, 26)
      ..cubicTo(69, 40, 56, 62, 50, 84)
      ..close();
    canvas.drawPath(rightShield, shieldPaint);

    // connection curves
    final leftCurve = Path()
      ..moveTo(22, 45)
      ..quadraticBezierTo(35, 31, 50, 45);
    canvas.drawPath(leftCurve, strokePaint);

    final rightCurve = Path()
      ..moveTo(78, 45)
      ..quadraticBezierTo(65, 31, 50, 45);
    canvas.drawPath(rightCurve, strokePaint);

    // central ring
    canvas.drawCircle(const Offset(50, 55), 18, Paint()..color = primaryColor.withValues(alpha: 0.8));
    canvas.drawCircle(const Offset(50, 55), 14, innerPaint);

    // star
    final star = Path()
      ..moveTo(50, 36)
      ..lineTo(54, 50)
      ..lineTo(69, 54)
      ..lineTo(54, 58)
      ..lineTo(50, 72)
      ..lineTo(46, 58)
      ..lineTo(31, 54)
      ..lineTo(46, 50)
      ..close();
    canvas.drawPath(star, fillPaint);

    // top leaves
    final leftLeaf = Path()
      ..moveTo(50, 36)
      ..quadraticBezierTo(44, 25, 36, 28)
      ..quadraticBezierTo(45, 33, 50, 36)
      ..close();
    canvas.drawPath(leftLeaf, fillPaint);

    final rightLeaf = Path()
      ..moveTo(50, 36)
      ..quadraticBezierTo(56, 25, 64, 28)
      ..quadraticBezierTo(55, 33, 50, 36)
      ..close();
    canvas.drawPath(rightLeaf, fillPaint);

    // sparkles
    _drawSparkle(canvas, const Offset(15, 24), primaryColor.withValues(alpha: 0.72));
    _drawSparkle(canvas, const Offset(90, 24), primaryColor.withValues(alpha: 0.72));
    _drawSparkle(canvas, const Offset(52, 10), primaryColor.withValues(alpha: 0.72));
    _drawSparkle(canvas, const Offset(20, 70), primaryColor.withValues(alpha: 0.72));
    _drawSparkle(canvas, const Offset(85, 70), primaryColor.withValues(alpha: 0.72));

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 3)
      ..lineTo(center.dx + 3, center.dy)
      ..lineTo(center.dx, center.dy + 3)
      ..lineTo(center.dx - 3, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HeroLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
