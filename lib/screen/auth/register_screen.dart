import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/register_screen_repository.dart';

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

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Tên không được để trống.';
    if (v.length < 2) return 'Tên phải chứa ít nhất 2 ký tự.';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email không được để trống.';
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$').hasMatch(v)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Mật khẩu không được để trống.';
    if (v.length < 6) return 'Mật khẩu phải chứa ít nhất 6 ký tự.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (v != _passwordController.text) {
      return 'Mật khẩu xác nhận không trùng khớp.';
    }
    return null;
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không trùng khớp!';
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
          response.message.isNotEmpty
              ? response.message
              : 'Đăng ký thất bại. Vui lòng thử lại.',
        );
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final cardColor = theme.colorScheme.surface;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 60,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // H1 - Title
                        Text(
                          'Gieo Hạt Mầm Đầu Tiên',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          'Ký kết khế ước và bắt đầu hành trình ma thuật của riêng bạn',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Name field ──────────────────────────────
                        _PillField(
                          controller: _nameController,
                          hint: 'Tên của bạn',
                          icon: Icons.spa_outlined, // Thay Sprout
                          textInputAction: TextInputAction.next,
                          cardColor: cardColor,
                          primary: primary,
                          validator: _validateName,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // ── Email field ──────────────────────────────
                        _PillField(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.directions_walk, // Thay Footprints
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          cardColor: cardColor,
                          primary: primary,
                          validator: _validateEmail,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                         // ── Password field ───────────────────────────
                         _PillField(
                           controller: _passwordController,
                           hint: 'Mật khẩu',
                           icon: Icons.key_rounded, // Thay KeyRound
                           obscureText: _obscurePassword,
                           textInputAction: TextInputAction.next,
                           cardColor: cardColor,
                           primary: primary,
                           validator: _validatePassword,
                           enabled: !_isLoading,
                         ),
                         const SizedBox(height: 16),
 
                         // ── Confirm Password field ───────────────────
                         _PillField(
                           controller: _confirmPasswordController,
                           hint: 'Xác nhận mật khẩu',
                           icon: Icons.key_rounded,
                           obscureText: _obscurePassword,
                           textInputAction: TextInputAction.done,
                           cardColor: cardColor,
                           primary: primary,
                           validator: _validateConfirmPassword,
                           enabled: !_isLoading,
                           onFieldSubmitted: (_) => _handleRegister(),
                         ),
                         const SizedBox(height: 12),
 
                         // ── Checkbox Show/Hide Password ───────────────
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 4),
                           child: Row(
                             children: [
                               SizedBox(
                                 width: 24,
                                 height: 24,
                                 child: Checkbox(
                                   value: !_obscurePassword,
                                   onChanged: _isLoading
                                       ? null
                                       : (val) {
                                           setState(() {
                                             _obscurePassword = !val!;
                                           });
                                         },
                                   activeColor: primary,
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               GestureDetector(
                                 onTap: _isLoading
                                     ? null
                                     : () {
                                         setState(() {
                                           _obscurePassword = !_obscurePassword;
                                         });
                                       },
                                 child: Text(
                                   'Hiển thị mật khẩu',
                                   style: theme.textTheme.bodyMedium?.copyWith(
                                     color: mutedForeground,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ),
                             ],
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
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                                label: 'Bắt Đầu Khế Ước',
                              ),
                        const SizedBox(height: 30),

                        // ── Login link ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đã ký kết khế ước?',
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
                                'Đăng nhập tại đây',
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

// ── Pill-shaped input field ─────────────────────────────────────────────────

class _PillField extends StatelessWidget {
  const _PillField({
    required this.controller,
    required this.hint,
    required this.icon,
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
  final IconData icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: enabled ? 0.95 : 0.6),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primary.withValues(alpha: enabled ? 0.85 : 0.5),
          ),
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
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.15),
                offset: const Offset(0, 8),
                blurRadius: 20,
              ),
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Material(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.foregroundColor,
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
