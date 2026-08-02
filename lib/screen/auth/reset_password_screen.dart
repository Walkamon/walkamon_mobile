import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';

import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/forgot_password_screen_repository.dart';
import '../../widgets/common/error_message_widget.dart';
import 'widgets/auth_style.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ForgotPasswordScreenRepository _authRepository =
      ForgotPasswordScreenRepository();

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  String? _requestCode;
  String? _email;
  String? _otp;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestCode == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _requestCode = args?['requestCode'] as String?;
      _email = args?['email'] as String?;
      _otp = args?['otp'] as String?;
      if (_otp != null && _otp!.isNotEmpty) {
        _otpController.text = _otp!;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'OTP không được để trống.';
    if (!RegExp(r'^\d{6}\$').hasMatch(trimmed))
      return 'OTP phải gồm đúng 6 chữ số.';
    return null;
  }

  String? _validatePassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) return 'Mật khẩu không được để trống.';
    if (trimmed.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (trimmed != _newPasswordController.text)
      return 'Mật khẩu xác nhận không khớp.';
    return null;
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_requestCode == null) {
      setState(() {
        _errorMessage = 'Không tìm thấy mã yêu cầu đặt lại mật khẩu.';
      });
      return;
    }

    final otp = _otp ?? _otpController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final response = await _authRepository.resetForgotPassword(
      requestCode: _requestCode!,
      otp: otp,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (r) => false);
      }
      return;
    }

    setState(() {
      _errorMessage = translateError(
        response.message.isNotEmpty
            ? response.message
            : 'Đặt lại mật khẩu thất bại.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            // Centered brand + card
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 44,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      const AuthBrand(tagline: 'Mỗi bước chân, một phép màu'),
                      const SizedBox(height: 18),

                      // big rounded white card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 26,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(250),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332B472E),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Đặt Lại Mật Mã',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AuthStyle.forestDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _otp == null
                                    ? (_email == null
                                          ? 'Nhập mã OTP trong email và chọn mật khẩu mới.'
                                          : 'Mã OTP đã được gửi đến $_email. Nhập mã và chọn mật khẩu mới.')
                                    : (_email == null
                                          ? 'Mã OTP đã được xác thực. Nhập mật khẩu mới.'
                                          : 'Mã OTP đã được xác thực cho $_email. Nhập mật khẩu mới.'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AuthStyle.forest.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 18),

                              if (_errorMessage != null) ...[
                                ErrorMessageWidget(message: _errorMessage!),
                                const SizedBox(height: 12),
                              ],

                              if (_otp == null) ...[
                                OutlinedField(
                                  controller: _otpController,
                                  hint: 'Mã OTP 6 số',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  maxLength: 6,
                                  validator: _validateOtp,
                                  prefix: Image.asset(
                                    AppAssets.authVerified,
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              OutlinedField(
                                controller: _newPasswordController,
                                hint: 'Mật khẩu mới',
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                validator: _validatePassword,
                                prefix: Image.asset(
                                  AppAssets.authKey,
                                  width: 22,
                                  height: 22,
                                ),
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Image.asset(
                                    _obscurePassword
                                        ? AppAssets.authVisibilityOff
                                        : AppAssets.authVisibility,
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              OutlinedField(
                                controller: _confirmPasswordController,
                                hint: 'Xác nhận mật khẩu',
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: _validateConfirmPassword,
                                onFieldSubmitted: (_) => _handleResetPassword(),
                                prefix: Image.asset(
                                  AppAssets.authVerified,
                                  width: 22,
                                  height: 22,
                                ),
                              ),

                              const SizedBox(height: 20),

                              FilledButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _handleResetPassword,
                                icon: Image.asset(
                                  AppAssets.authSend,
                                  width: 26,
                                  height: 26,
                                ),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Đặt Lại Mật Mã',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  backgroundColor: AuthStyle.forest,
                                  foregroundColor: AuthStyle.cream,
                                  shape: const StadiumBorder(
                                    side: BorderSide(
                                      color: AppColors.woodDeep,
                                      width: 2,
                                    ),
                                  ),
                                ),
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

            // small back icon in top-left
            PositionedGameBackButton(
              semanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// small rounded box for icon prefixes
// removed _IconSlot; prefixes now use left-aligned Image.asset icons

class OutlinedField extends StatelessWidget {
  const OutlinedField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.validator,
    this.prefix,
    this.suffix,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AuthStyle.forestDark,
      ),
      cursorColor: AuthStyle.forestDark,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
          fontWeight: FontWeight.w600,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withAlpha(250),
        prefixIcon: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: prefix,
              )
            : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE9B86A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE9B86A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE9B86A), width: 2),
        ),
      ),
    );
  }
}
