import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_wordmark.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/register_screen_repository.dart';
import 'widgets/auth_style.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final RegisterScreenRepository _authRepository = RegisterScreenRepository();

  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateName(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.registerNameRequired;
    if (v.length < 2) return l10n.registerNameMinLength;
    return null;
  }

  String? _validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.loginEmailRequired;
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$').hasMatch(v)) {
      return l10n.loginEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.loginPasswordRequired;
    if (v.length < 6) return l10n.registerPasswordMinLength;
    return null;
  }

  String? _validateConfirmPassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.registerConfirmPasswordRequired;
    if (v != _passwordController.text) {
      return l10n.registerPasswordMismatch;
    }
    return null;
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _handleRegister() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = l10n.registerPasswordMismatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _authRepository.register(
      email: _emailController.text.trim(),
      username: _nameController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success && response.data != null) {
      // Đăng ký thành công, chuyển sang màn hình OTP
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/auth/otp_register',
          arguments: {
            'email': _emailController.text.trim(),
            'requestCode': response.data!.requestCode,
          },
        );
      }
    } else {
      // Đăng ký thất bại, hiển thị thông báo lỗi từ API
      setState(() {
        _errorMessage = translateError(
          response.message.isNotEmpty ? response.message : l10n.registerFailed,
        );
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const primary = AppColors.buttonGreen;
    final mutedForeground = AppColors.oliveDeep.withValues(alpha: 0.82);
    const accent = AppColors.woodDeep;
    const registerButtonColor = AppColors.buttonYellow;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.authGarden,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x120F2819), Color(0x00FFF7E3), Color(0x38365525)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameWordmark(
                              title: l10n.appTitle,
                              tagline: l10n.welcomeTagline,
                              width: 270,
                            ),
                            const SizedBox(height: 22),
                            _RegisterCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GameButtonLabel(
                                      l10n.registerTitle,
                                      fontSize: 23,
                                      letterSpacing: 0.1,
                                      color: AppColors.woodDeep,
                                      outlineColor: AppColors.creamDeep,
                                      outlineWidth: 2.5,
                                    ),
                                    const SizedBox(height: 9),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: GameButtonLabel(
                                        l10n.registerSubtitle,
                                        fontSize: 14,
                                        letterSpacing: 0.1,
                                        color: AppColors.oliveDeep,
                                        outlineColor: AppColors.ivory,
                                        outlineWidth: 2,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Error Banner
                                    if (_errorMessage != null) ...[
                                      AuthMessageBanner(
                                        message: _errorMessage!,
                                        isError: true,
                                      ),
                                      const SizedBox(height: 20),
                                    ],

                                    // ── Name field ──────────────────────────────
                                    _PillField(
                                      controller: _nameController,
                                      hint: l10n.registerNameHint,
                                      iconAsset: AppAssets.authRegisterSeed,
                                      textInputAction: TextInputAction.next,
                                      cardColor: Colors.white,
                                      primary: primary,
                                      validator: (value) =>
                                          _validateName(context, value),
                                      enabled: !_isLoading,
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Email field ──────────────────────────────
                                    _PillField(
                                      controller: _emailController,
                                      hint: l10n.loginEmail,
                                      iconAsset: AppAssets.authMail,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      cardColor: Colors.white,
                                      primary: primary,
                                      validator: (value) =>
                                          _validateEmail(context, value),
                                      enabled: !_isLoading,
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Password field ───────────────────────────
                                    _PillField(
                                      controller: _passwordController,
                                      hint: l10n.loginPassword,
                                      iconAsset: AppAssets.authLock,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      cardColor: Colors.white,
                                      primary: primary,
                                      validator: (value) =>
                                          _validatePassword(context, value),
                                      enabled: !_isLoading,
                                      suffix: IconButton(
                                        tooltip: _obscurePassword
                                            ? l10n.showPassword
                                            : l10n.hidePassword,
                                        onPressed: _isLoading
                                            ? null
                                            : () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                        icon: Image.asset(
                                          _obscurePassword
                                              ? AppAssets.authVisibilityOff
                                              : AppAssets.authVisibility,
                                          width: 25,
                                          height: 25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Confirm Password field ───────────────────
                                    _PillField(
                                      controller: _confirmPasswordController,
                                      hint: l10n.registerConfirmPassword,
                                      iconAsset: AppAssets.authLock,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      cardColor: Colors.white,
                                      primary: primary,
                                      validator: (value) =>
                                          _validateConfirmPassword(
                                            context,
                                            value,
                                          ),
                                      enabled: !_isLoading,
                                      onFieldSubmitted: (_) =>
                                          _handleRegister(),
                                      suffix: IconButton(
                                        tooltip: _obscurePassword
                                            ? l10n.showPassword
                                            : l10n.hidePassword,
                                        onPressed: _isLoading
                                            ? null
                                            : () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                        icon: Image.asset(
                                          _obscurePassword
                                              ? AppAssets.authVisibilityOff
                                              : AppAssets.authVisibility,
                                          width: 25,
                                          height: 25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // ── Checkbox Show/Hide Password ───────────────

                                    // ── Checkbox Agree to Privacy Policy & Terms ───────────
                                    _RegisterOptionTile(
                                      value: _acceptTerms,
                                      primary: primary,
                                      enabled: !_isLoading,
                                      onChanged: (value) {
                                        setState(() => _acceptTerms = value);
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: AppColors.oliveDeep,
                                                fontWeight: FontWeight.w700,
                                                height: 1.35,
                                              ),
                                          children: [
                                            TextSpan(
                                              text: l10n.registerAgreeTerms,
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: _HoverLinkText(
                                                text: l10n.privacyPolicy,
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/auth/privacy',
                                                  );
                                                },
                                                normalColor: accent,
                                                hoverColor: primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Submit button ─────────────────────────────
                                    _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : _TapScaleButton(
                                            onPressed: _handleRegister,
                                            backgroundColor:
                                                registerButtonColor,
                                            foregroundColor: Colors.white,
                                            label: l10n.registerButton,
                                            enabled: _acceptTerms,
                                          ),
                                    const SizedBox(height: 20),

                                    // ── Login link ─────────────────────────────
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text(
                                          l10n.registerAlreadyAccount,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: mutedForeground,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _isLoading
                                              ? null
                                              : Navigator.pushReplacementNamed(
                                                  context,
                                                  '/auth/login',
                                                ),
                                          child: Text(
                                            l10n.registerLoginHere,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: accent,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Back button ──
                PositionedGameBackButton(
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Standalone register card ─────────────────────────────────────────────────

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.wood, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2B472E),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RegisterOptionTile extends StatelessWidget {
  const _RegisterOptionTile({
    required this.value,
    required this.primary,
    required this.enabled,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final Color primary;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Checkbox(
                  value: value,
                  onChanged: enabled
                      ? (nextValue) => onChanged(nextValue ?? false)
                      : null,
                  activeColor: primary,
                  checkColor: AppColors.buttonText,
                  side: const BorderSide(
                    color: AppColors.buttonBorder,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pill-shaped input field ─────────────────────────────────────────────────

class _PillField extends StatelessWidget {
  const _PillField({
    required this.controller,
    required this.hint,
    required this.iconAsset,
    required this.cardColor,
    required this.primary,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String iconAsset;
  final Color cardColor;
  final Color primary;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      cursorColor: primary,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.inkDark,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          color: AppColors.oliveDeep,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(iconAsset, width: 28, height: 28),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: cardColor.withValues(alpha: enabled ? 0.78 : 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.wood, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.wood, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.woodDeep, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB74A3A)),
        ),
      ),
    );
  }
}

// ── Tap-scale submit button ──────────────────────────────────────────────────

class _TapScaleButton extends StatefulWidget {
  const _TapScaleButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;
  final bool enabled;

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final disabledBg = AppColors.buttonYellow.withValues(alpha: 0.55);
    const disabledFg = Colors.white;

    final bgColor = widget.enabled ? widget.backgroundColor : disabledBg;
    final fgColor = widget.enabled ? widget.foregroundColor : disabledFg;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _scale = 0.95) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: widget.enabled ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(
        scale: widget.enabled ? _scale : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.28),
                      offset: const Offset(0, 8),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.18),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.buttonBorder, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.enabled ? widget.onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GameButtonLabel(
                  widget.label,
                  color: fgColor,
                  outlineColor: AppColors.buttonBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverLinkText extends StatefulWidget {
  const _HoverLinkText({
    required this.text,
    required this.onTap,
    required this.normalColor,
    required this.hoverColor,
  });

  final String text;
  final VoidCallback onTap;
  final Color normalColor;
  final Color hoverColor;

  @override
  State<_HoverLinkText> createState() => _HoverLinkTextState();
}

class _HoverLinkTextState extends State<_HoverLinkText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _isHovered ? widget.hoverColor : widget.normalColor,
            decoration: _isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
