import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../widgets/common/error_message_widget.dart';

import '../../data/repositories/forgot_password_screen_repository.dart';
import '../../data/repositories/otp_register_screen_repository.dart';
import '../../widgets/common/egg_shape.dart';

class OTP_Verification extends StatefulWidget {
  const OTP_Verification({super.key});

  @override
  State<OTP_Verification> createState() => _OTP_VerificationState();
}

class _OTP_VerificationState extends State<OTP_Verification>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final OtpScreenRepository _authRepository = OtpScreenRepository();
  final ForgotPasswordScreenRepository _forgotPasswordRepository =
      ForgotPasswordScreenRepository();
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  String? _currentRequestCode;
  String? _email;
  String? _nextRoute;
  String? _errorMessage;
  String? _successMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentRequestCode == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _currentRequestCode = args?['requestCode'] as String?;
      _email = args?['email'] as String?;
      _nextRoute = args?['nextRoute'] as String?;
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
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  bool get _isOtpComplete =>
      _controllers.every((c) => c.text.trim().length == 1);

  bool get _isOtpDigitsOnly =>
      _controllers.every((c) => RegExp(r'^\d$').hasMatch(c.text.trim()));

  bool get _isForgotPasswordFlow => _nextRoute == '/auth/reset-password';

  String? _otpErrorMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errors = <String>[];
    if (!_isOtpComplete) {
      errors.add(l10n.otpIncomplete);
    }
    if (!_isOtpDigitsOnly) {
      errors.add(l10n.otpDigitsOnly);
    }
    if (errors.isEmpty) return null;
    return errors.join(' ');
  }

  void _handleChange(int index, String value) {
    if (value.length > 1) {
      value = value.substring(value.length - 1);
    }

    setState(() {
      _controllers[index].text = value;
      _controllers[index].selection = TextSelection.collapsed(
        offset: value.length,
      );
    });

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleBackspace(int index) {
    if (index > 0) {
      setState(() {
        _controllers[index - 1].text = '';
      });
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleVerify() async {
    final l10n = AppLocalizations.of(context);
    final errorMessage = _otpErrorMessage(context);
    
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (errorMessage != null) {
      setState(() {
        _errorMessage = errorMessage;
      });
      return;
    }
    if (_currentRequestCode == null) {
      setState(() {
        _errorMessage = l10n.otpRequestCodeNotFound;
      });
      return;
    }
    final otp = _controllers.map((c) => c.text.trim()).join();

    if (_isForgotPasswordFlow) {
      Navigator.pushNamed(
        context,
        '/auth/reset-password',
        arguments: {
          'requestCode': _currentRequestCode,
          'email': _email,
          'otp': otp,
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final response = await _authRepository.verifyOtp(
      requestCode: _currentRequestCode!,
      otp: otp,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (response.success) {
      setState(() {
        _successMessage = l10n.otpVerifySuccess;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth/login',
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = translateError(
          response.message.isNotEmpty
              ? response.message
              : l10n.otpInvalid,
        );
      });
    }
  }

  Future<dynamic> _resendForgotPasswordOtp() async {
    if (_email == null || _email!.isEmpty) {
      return null;
    }
    return _forgotPasswordRepository.forgotPassword(email: _email!);
  }

  void _handleResendOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (_isForgotPasswordFlow) {
      if (_email == null || _email!.isEmpty) {
        setState(() {
          _errorMessage = l10n.otpEmailNotFound;
        });
        return;
      }
    } else if (_currentRequestCode == null) {
      setState(() {
        _errorMessage = l10n.otpRequestCodeNotFound;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final response = _isForgotPasswordFlow
        ? await _resendForgotPasswordOtp()
        : await _authRepository.resendOtp(requestCode: _currentRequestCode!);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (response == null) {
      setState(() {
        _errorMessage = l10n.otpEmailNotFound;
      });
      return;
    }
    if (response.success && response.data != null) {
      _currentRequestCode = response.data!.requestCode;
      setState(() {
        _successMessage = l10n.otpResendSuccess;
      });
    } else {
      setState(() {
        _errorMessage = translateError(
          response.message.isNotEmpty
              ? response.message
              : l10n.otpResendFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Scaffold(
      body: FadeTransition(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.otpTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.otpSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          ErrorMessageWidget(message: _errorMessage!),
                          const SizedBox(height: 20),
                        ],

                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              _successMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_controllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: EggOtpField(
                                width: 44,
                                height: 65,
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                primary: primary,
                                textStyle: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                      fontSize: 20,
                                    ),
                                onChanged: (value) => _handleChange(index, value),
                                onBackspace: () => _handleBackspace(index),
                                onSubmitted: () {
                                  if (index == _controllers.length - 1) {
                                    _handleVerify();
                                  }
                                },
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
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
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(l10n.otpVerifyButton),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _handleResendOtp,
                            child: Text(
                              l10n.otpResendButton,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isLoading
                                    ? mutedForeground
                                    : theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
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
      ),
    );
  }
}