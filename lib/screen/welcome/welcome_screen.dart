import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_wordmark.dart';

import '../../core/auth/google_sign_in_auth.dart';
import '../../core/constants/app_assets.dart';
import '../../core/l10n/locale_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';
import '../../widgets/common/google_icon.dart';
import '../auth/widgets/auth_style.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    // Tạo một khoảng hoãn nhỏ (100ms) để Flutter Web ổn định Engine rồi mới quét dữ liệu
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _checkAutoLogin();
      }
    });
  }

  Future<void> _checkAutoLogin() async {
    try {
      final authProvider = context.read<GameStateProvider>();
      bool isLoggedIn = await authProvider.tryAutoLogin();

      if (!mounted) return;

      if (isLoggedIn) {
        final userId = authProvider.user?.id ?? '';

        if (userId.isNotEmpty && mounted) {
          context.read<StepTrackingProvider>().startForUser(userId);
        }

        if (!mounted) return;

        // Chuyển trang trực tiếp
        Navigator.pushReplacementNamed(context, '/seed');
      }
    } catch (e) {
      // Bọc catch để nếu có lỗi ngầm xảy ra, app không bị đứng hình trắng xóa
      debugPrint("Lỗi AutoLogin ngầm: $e");
    }
  }

  Future<void> _handleGoogleLogin() async {
    final provider = context.read<GameStateProvider>();

    try {
      final idToken = await GoogleSignInAuth.getIdToken();
      final success = await provider.googleLogin(idToken: idToken);

      if (!mounted) return;

      if (success) {
        final userId = provider.user?.id ?? '';
        if (userId.isNotEmpty && mounted) {
          await context.read<StepTrackingProvider>().startForUser(userId);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/seed');
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
              : AppLocalizations.of(context).googleLoginFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AuthStyle.forest;
    final loginButtonColor = isDark
        ? AppColors.darkPrimary
        : AppColors.buttonGreen;
    const loginButtonForeground = AppColors.buttonText;
    final registerButtonColor = isDark
        ? AppColors.darkAccent
        : AppColors.buttonYellow;
    const registerButtonForeground = AppColors.buttonText;
    const registerButtonBorder = AppColors.buttonBorder;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.welcome,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x120F2819),
                  Color(0x00FFF7E3),
                  Color(0x38365525),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _TopIconButton(
                      icon: Icons.explore_outlined,
                      asset: AppAssets.iconSettingsSystem,
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
                          child: GameWordmark(
                            title: l10n.appTitle,
                            tagline: l10n.welcomeTagline,
                          ),
                        ),
                        const Spacer(flex: 2),
                        _AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 200),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: AuthCard(
                              child: Column(
                                children: [
                                  _PrimaryButton(
                                    label: l10n.welcomeLogin,
                                    backgroundColor: loginButtonColor,
                                    foregroundColor: loginButtonForeground,
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/auth/login',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _OutlineButton(
                                    label: l10n.welcomeRegister,
                                    backgroundColor: registerButtonColor,
                                    foregroundColor: registerButtonForeground,
                                    borderColor: registerButtonBorder,
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/auth/register',
                                    ),
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
                                          l10n.welcomeOr,
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
                                    cardColor: Colors.white.withValues(
                                      alpha: 0.78,
                                    ),
                                    borderColor: registerButtonBorder,
                                    foregroundColor: AuthStyle.forestDark,
                                    mutedColor: muted,
                                    onPressed: _handleGoogleLogin,
                                  ),
                                ],
                              ),
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
    this.asset,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String? asset;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCard,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.woodDeep, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: AppIcon(icon, asset: asset, size: 32, color: color),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: AppColors.woodDeep, width: 2),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _WelcomeButtonLeafPainter()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GameButtonLabel(
                  label,
                  fontSize: 18,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeButtonLeafPainter extends CustomPainter {
  const _WelcomeButtonLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 104) return;
    final fill = Paint()..color = AppColors.oliveDeep;
    final edge = Paint()
      ..color = AppColors.woodDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void leaf(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: 16, height: 8);
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    final y = size.height / 2;
    leaf(Offset(9, y - 5), -0.55);
    leaf(Offset(9, y + 5), 0.55);
    leaf(Offset(size.width - 9, y - 5), 0.55);
    leaf(Offset(size.width - 9, y + 5), -0.55);
  }

  @override
  bool shouldRepaint(covariant _WelcomeButtonLeafPainter oldDelegate) => false;
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: 2),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: GameButtonLabel(label, fontSize: 18, color: foregroundColor),
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
                  AppLocalizations.of(context).welcomeGoogleLogin,
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
  const _SettingsOverlay({required this.onClose});

  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.42),
        child: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 410,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.84,
                  ),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: AppColors.authCard.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.wood, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Consumer<GameStateProvider>(
                      builder: (context, gameState, _) {
                        final settings = gameState.settings;
                        final isVi = LocaleHelper.isVietnamese(
                          settings.languageCode,
                        );
                        final languageLabel = isVi
                            ? l10n.languageVi
                            : l10n.languageEn;

                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: GameButtonLabel(
                                        l10n.gameSettings,
                                        fontSize: 20,
                                        color: AppColors.woodDeep,
                                        outlineColor: AppColors.authCard,
                                        outlineWidth: 3.5,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: onClose,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 42,
                                      height: 42,
                                    ),
                                    icon: const AppIcon(
                                      Icons.close_rounded,
                                      size: 30,
                                      color: AppColors.woodDeep,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _WelcomeSettingsPanel(
                                child: Column(
                                  children: [
                                    _WelcomeLanguageRow(
                                      label: l10n.language,
                                      value: languageLabel,
                                      onTap: () {
                                        final code = isVi ? 'en-US' : 'vi-VN';
                                        context
                                            .read<GameStateProvider>()
                                            .setLanguageCode(code);
                                      },
                                    ),
                                    _WelcomeSettingsSwitch(
                                      label: l10n.bgm,
                                      icon: Icons.music_note_rounded,
                                      asset: AppAssets.iconMusic,
                                      value: settings.backgroundMusicEnabled,
                                      onChanged: (value) => context
                                          .read<GameStateProvider>()
                                          .updateSettings(
                                            backgroundMusicEnabled: value,
                                          ),
                                    ),
                                    _WelcomeSettingsSwitch(
                                      label: l10n.sfx,
                                      icon: Icons.volume_up_rounded,
                                      asset: AppAssets.iconVolume,
                                      value: settings.soundEnabled,
                                      onChanged: (value) => context
                                          .read<GameStateProvider>()
                                          .updateSettings(soundEnabled: value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

class _WelcomeSettingsPanel extends StatelessWidget {
  const _WelcomeSettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.leafLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.oliveDeep, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WelcomeLanguageRow extends StatelessWidget {
  const _WelcomeLanguageRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.authCard.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.wood, width: 1.35),
          ),
          child: Row(
            children: [
              const _WelcomeSettingIcon(
                icon: Icons.language_rounded,
                asset: AppAssets.iconLanguageSystem,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.woodDeep,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.oliveDeep,
                ),
              ),
              const SizedBox(width: 6),
              const AppIcon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.woodDeep,
                useAsset: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSettingsSwitch extends StatelessWidget {
  const _WelcomeSettingsSwitch({
    required this.label,
    required this.icon,
    this.asset,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? asset;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.wood, width: 1.35),
      ),
      child: Row(
        children: [
          _WelcomeSettingIcon(icon: icon, asset: asset),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.woodDeep,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.authCard,
            activeTrackColor: AppColors.buttonGreen,
            inactiveThumbColor: AppColors.authCard,
            inactiveTrackColor: AppColors.creamDeep,
            trackOutlineColor: const WidgetStatePropertyAll(AppColors.woodDeep),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSettingIcon extends StatelessWidget {
  const _WelcomeSettingIcon({required this.icon, this.asset});

  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wood, width: 1.3),
      ),
      child: asset != null
          ? Image.asset(asset!, width: 30, height: 30)
          : AppIcon(icon, size: 25, color: AppColors.woodDeep),
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
    );
    _bounce = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final glowColor = isDark ? AppColors.darkPrimary : AppColors.leafBright;
    final outerStroke = isDark ? AppColors.darkForeground : AppColors.ivory;
    final innerStroke = isDark ? AppColors.olive : AppColors.oliveDeep;
    const titleFill = AppColors.goldLight;
    const taglineFill = AppColors.leafLight;

    return SizedBox(
      width: widget.size,
      height: widget.size * 0.52,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounce.value),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _HeroLogoPainter(
                primaryColor: glowColor,
                innerColor: outerStroke,
                strokeColor: innerStroke,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _outlinedLogoText(
                    text: l10n.appTitle,
                    fontSize: 43,
                    fillColor: titleFill,
                    innerStroke: innerStroke,
                    outerStroke: outerStroke,
                    outerWidth: 10,
                    innerWidth: 5.5,
                    letterSpacing: -1.4,
                  ),
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: widget.size * 0.84),
                    child: _outlinedLogoText(
                      text: l10n.welcomeTagline,
                      fontSize: 19,
                      fillColor: taglineFill,
                      innerStroke: innerStroke,
                      outerStroke: outerStroke,
                      outerWidth: 7,
                      innerWidth: 3.8,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlinedLogoText({
    required String text,
    required double fontSize,
    required Color fillColor,
    required Color innerStroke,
    required Color outerStroke,
    required double outerWidth,
    required double innerWidth,
    required double letterSpacing,
  }) {
    TextStyle style({Color? color, Paint? foreground}) {
      return TextStyle(
        color: color,
        foreground: foreground,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 0.96,
        letterSpacing: letterSpacing,
      );
    }

    Text layer(TextStyle textStyle) => Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: textStyle,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        layer(
          style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = outerWidth
              ..color = outerStroke,
          ),
        ),
        layer(
          style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = innerWidth
              ..color = innerStroke,
          ),
        ),
        layer(
          style(color: fillColor).copyWith(
            shadows: const [
              Shadow(
                color: Color(0x55352318),
                blurRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
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
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // The sprout grows directly from the tail of the Walkamon wordmark.
    final stem = Path()
      ..moveTo(84, 22)
      ..quadraticBezierTo(84, 17, 81, 14);
    canvas.drawPath(stem, strokePaint);

    final leftLeaf = Path()
      ..moveTo(83, 18)
      ..cubicTo(75, 18, 74, 11, 81, 11)
      ..cubicTo(85, 12, 85, 15, 83, 18)
      ..close();
    canvas.drawPath(leftLeaf, fillPaint);
    canvas.drawPath(leftLeaf, strokePaint);

    final rightLeaf = Path()
      ..moveTo(84, 17)
      ..cubicTo(86, 10, 94, 10, 92, 16)
      ..cubicTo(90, 20, 86, 20, 84, 17)
      ..close();
    canvas.drawPath(rightLeaf, fillPaint);
    canvas.drawPath(rightLeaf, strokePaint);

    _drawSparkle(canvas, const Offset(18, 17), innerColor);
    _drawSparkle(canvas, const Offset(73, 7), innerColor);
    _drawSparkle(canvas, const Offset(96, 27), innerColor);

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
