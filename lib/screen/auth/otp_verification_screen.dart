import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_wordmark.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/forgot_password_screen_repository.dart';
import '../../data/repositories/otp_register_screen_repository.dart';
import '../../widgets/common/egg_shape.dart';
import 'widgets/auth_style.dart';

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
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
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
    if (!_isOtpComplete) errors.add(l10n.otpIncomplete);
    if (!_isOtpDigitsOnly) errors.add(l10n.otpDigitsOnly);
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
      setState(() => _controllers[index - 1].text = '');
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    final l10n = AppLocalizations.of(context);
    final errorMessage = _otpErrorMessage(context);

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (errorMessage != null) {
      setState(() => _errorMessage = errorMessage);
      return;
    }

    if (_currentRequestCode == null) {
      setState(() => _errorMessage = l10n.otpRequestCodeNotFound);
      return;
    }

    final otp = _controllers.map((c) => c.text.trim()).join();

    if (_isForgotPasswordFlow) {
      setState(() => _isLoading = true);
      final response = await _forgotPasswordRepository.verifyForgotPasswordOtp(
        requestCode: _currentRequestCode!,
        otp: otp,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      final resetToken = response.data?.resetToken.trim() ?? '';
      if (response.success && resetToken.isNotEmpty) {
        setState(() => _successMessage = l10n.otpVerifySuccess);
        Navigator.pushNamed(
          context,
          '/auth/reset-password',
          arguments: {
            'requestCode': response.data!.requestCode.isNotEmpty
                ? response.data!.requestCode
                : _currentRequestCode,
            'email': _email,
            'resetToken': resetToken,
          },
        );
      } else {
        setState(() {
          _errorMessage = translateError(
            response.message.isNotEmpty ? response.message : l10n.otpInvalid,
          );
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    final response = await _authRepository.verifyOtp(
      requestCode: _currentRequestCode!,
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      setState(() => _successMessage = l10n.otpVerifySuccess);
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
          response.message.isNotEmpty ? response.message : l10n.otpInvalid,
        );
      });
    }
  }

  Future<dynamic> _resendForgotPasswordOtp() async {
    if (_email == null || _email!.isEmpty) return null;
    return _forgotPasswordRepository.forgotPassword(email: _email!);
  }

  Future<void> _handleResendOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (_isForgotPasswordFlow) {
      if (_email == null || _email!.isEmpty) {
        setState(() => _errorMessage = l10n.otpEmailNotFound);
        return;
      }
    } else if (_currentRequestCode == null) {
      setState(() => _errorMessage = l10n.otpRequestCodeNotFound);
      return;
    }

    setState(() => _isLoading = true);
    final response = _isForgotPasswordFlow
        ? await _resendForgotPasswordOtp()
        : await _authRepository.resendOtp(requestCode: _currentRequestCode!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response == null) {
      setState(() => _errorMessage = l10n.otpEmailNotFound);
      return;
    }

    if (response.success && response.data != null) {
      _currentRequestCode = response.data!.requestCode;
      setState(() => _successMessage = l10n.otpResendSuccess);
    } else {
      setState(() {
        _errorMessage = translateError(
          response.message.isNotEmpty ? response.message : l10n.otpResendFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AuthGardenScaffold(
      child: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameWordmark(
                                title: l10n.appTitle,
                                tagline: l10n.welcomeTagline,
                                width: 270,
                              ),
                              const SizedBox(height: 22),
                              AuthCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GameButtonLabel(
                                      l10n.otpTitle,
                                      fontSize: 23,
                                      letterSpacing: 0.1,
                                      color: AppColors.woodDeep,
                                      outlineColor: AppColors.creamDeep,
                                      outlineWidth: 2.5,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.otpSubtitle,
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.oliveDeep,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      AuthMessageBanner(
                                        message: _errorMessage!,
                                        isError: true,
                                      ),
                                    ],
                                    if (_successMessage != null) ...[
                                      const SizedBox(height: 16),
                                      AuthMessageBanner(
                                        message: _successMessage!,
                                        isError: false,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _controllers.length,
                                        (index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: EggOtpField(
                                              width: 44,
                                              height: 65,
                                              controller: _controllers[index],
                                              focusNode: _focusNodes[index],
                                              primary: AppColors.wood,
                                              textStyle: textTheme.headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.woodDeep,
                                                    fontSize: 20,
                                                  ),
                                              onChanged: (value) =>
                                                  _handleChange(index, value),
                                              onBackspace: () =>
                                                  _handleBackspace(index),
                                              onSubmitted: () {
                                                if (index ==
                                                    _controllers.length - 1) {
                                                  _handleVerify();
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AuthPrimaryButton(
                                      label: l10n.otpVerifyButton,
                                      isLoading: _isLoading,
                                      onPressed: _handleVerify,
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleResendOtp,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AuthStyle.rust,
                                      ),
                                      child: Text(
                                        l10n.otpResendButton,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedGameBackButton(
            semanticLabel: l10n.loginBack,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
