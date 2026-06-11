import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/forgot_password_screen_repository.dart';

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
      duration: const Duration(milliseconds: 450),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero).animate(
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
    if (trimmed.isEmpty) {
      return 'OTP không được để trống.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'OTP phải gồm đúng 6 chữ số.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Mật khẩu không được để trống.';
    }
    if (trimmed.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu.';
    }
    if (trimmed != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth/login',
          (route) => false,
        );
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
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final cardColor = theme.colorScheme.surface;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 80,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Đặt Lại Mật Mã',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _otp == null
                              ? (_email == null
                                    ? 'Nhập mã OTP trong email và chọn mật khẩu mới.'
                                    : 'Mã OTP đã được gửi đến $_email. Nhập mã và chọn mật khẩu mới.')
                              : (_email == null
                                    ? 'Mã OTP đã được xác thực. Nhập mật khẩu mới.'
                                    : 'Mã OTP đã được xác thực cho $_email. Nhập mật khẩu mới.'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                          const SizedBox(height: 12),
                        ],
                        if (_otp == null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              maxLength: 6,
                              validator: _validateOtp,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Mã OTP 6 số',
                                hintStyle: theme.textTheme.titleMedium
                                    ?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha((0.6 * 255).round()),
                                      fontWeight: FontWeight.w600,
                                    ),
                                border: InputBorder.none,
                                isDense: true,
                                prefixIcon: Icon(
                                  Icons.verified_rounded,
                                  color: primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            validator: _validatePassword,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu mới',
                              hintStyle: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  (0.6 * 255).round(),
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              prefixIcon: Icon(
                                Icons.key_rounded,
                                color: primary,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                            onFieldSubmitted: (_) => _handleResetPassword(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Xác nhận mật khẩu',
                              hintStyle: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  (0.6 * 255).round(),
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              prefixIcon: Icon(
                                Icons.lock_reset_rounded,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            textStyle: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Đặt Lại Mật Mã'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 24,
              child: SafeArea(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: primary, size: 24),
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
