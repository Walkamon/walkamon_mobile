import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/register_screen_repository.dart';
import '../../widgets/common/error_message_widget.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

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
    final primary = theme.colorScheme.primary;
    // This screen owns a white card, so its content colors must keep enough
    // contrast regardless of the app brightness or the background artwork.
    final mutedForeground = Colors.black.withValues(alpha: 0.62);
    final accent = AppColors.lightAccent;
    const registerButtonColor = Color(0xFFB7D53B);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 60,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _RegisterCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // H1 - Title
                          Text(
                            l10n.registerTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.87),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            l10n.registerSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mutedForeground,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Error Banner
                          if (_errorMessage != null) ...[
                            ErrorMessageWidget(message: _errorMessage!),
                            const SizedBox(height: 20),
                          ],

                          // ── Name field ──────────────────────────────
                          _PillField(
                            controller: _nameController,
                            hint: l10n.registerNameHint,
                            iconAsset:
                                'assets/Mobile/icon/auth/register_seed.png',
                            textInputAction: TextInputAction.next,
                            cardColor: Colors.white,
                            primary: primary,
                            validator: (value) => _validateName(context, value),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),

                          // ── Email field ──────────────────────────────
                          _PillField(
                            controller: _emailController,
                            hint: l10n.loginEmail,
                            iconAsset: 'assets/Mobile/icon/auth/mail.png',
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
                            iconAsset: 'assets/Mobile/icon/auth/lock.png',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            cardColor: Colors.white,
                            primary: primary,
                            validator: (value) =>
                                _validatePassword(context, value),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),

                          // ── Confirm Password field ───────────────────
                          _PillField(
                            controller: _confirmPasswordController,
                            hint: l10n.registerConfirmPassword,
                            iconAsset: 'assets/Mobile/icon/auth/lock.png',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            cardColor: Colors.white,
                            primary: primary,
                            validator: (value) =>
                                _validateConfirmPassword(context, value),
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 12),

                          // ── Checkbox Show/Hide Password ───────────────
                          _RegisterOptionTile(
                            value: !_obscurePassword,
                            primary: primary,
                            enabled: !_isLoading,
                            onChanged: (value) {
                              setState(() => _obscurePassword = !value);
                            },
                            child: Text(
                              l10n.showPassword,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(text: l10n.registerAgreeTerms),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
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
                              ? const Center(child: CircularProgressIndicator())
                              : _TapScaleButton(
                                  onPressed: _handleRegister,
                                  backgroundColor: registerButtonColor,
                                  foregroundColor: const Color(0xFF26310D),
                                  label: l10n.registerButton,
                                  enabled: _acceptTerms,
                                ),
                          const SizedBox(height: 30),

                          // ── Login link ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.registerAlreadyAccount,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedForeground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _isLoading
                                    ? null
                                    : Navigator.pushReplacementNamed(
                                        context,
                                        '/auth/login',
                                      ),
                                child: Text(
                                  l10n.registerLoginHere,
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                ),
              ),
            ),

            // ── Back button ──
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _isLoading
                        ? null
                        : Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/', // Quay lại Welcome
                            (route) => false,
                          ),
                    icon: Icon(
                      Icons.arrow_back,
                      color: primary.withValues(alpha: 0.9),
                      size: 24,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standalone register card ─────────────────────────────────────────────────

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 22 : 56,
            vertical: compact ? 32 : 40,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1EF),
            borderRadius: BorderRadius.circular(compact ? 28 : 34),
            border: Border.all(
              color: AppColors.lightBorder.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                offset: const Offset(0, 18),
                blurRadius: 44,
              ),
              BoxShadow(
                color: AppColors.lightPrimary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: child,
        );
      },
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
                  side: BorderSide(
                    color: AppColors.lightForeground.withValues(alpha: 0.55),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: enabled ? 0.98 : 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: primary.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(iconAsset, width: 28, height: 28, fit: BoxFit.contain),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              enabled: enabled,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.87),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              validator: validator,
              onFieldSubmitted: onFieldSubmitted,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final disabledBg = isDark
        ? const Color(0xFF718029)
        : const Color(0xFFDDE8A5);
    final disabledFg = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF66723A);

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
            borderRadius: BorderRadius.circular(32),
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
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: widget.enabled ? widget.onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: 0.5,
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
