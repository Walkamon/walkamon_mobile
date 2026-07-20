import 'package:flutter/material.dart';

import 'package:walkamon_mobile/l10n/app_localizations.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/forgot_password_screen_repository.dart';
import 'widgets/auth_style.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ForgotPasswordScreenRepository _authRepository =
      ForgotPasswordScreenRepository();

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.loginEmailRequired;
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$').hasMatch(trimmed)) {
      return l10n.loginEmailInvalid;
    }
    return null;
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final response = await _authRepository.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      Navigator.pushNamed(
        context,
        '/auth/otp_verification',
        arguments: {
          'requestCode': response.data!.requestCode,
          'email': _emailController.text.trim(),
          'nextRoute': '/auth/reset-password',
        },
      );
      return;
    }

    if (response.success) {
      setState(() => _successMessage = l10n.forgotPasswordResetSent);
      return;
    }

    setState(() {
      _errorMessage = translateError(
        response.message.isNotEmpty
            ? response.message
            : l10n.forgotPasswordRequestFailed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AuthGardenScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AuthRoundIconButton(
                              icon: Icons.arrow_back_rounded,
                              semanticLabel: l10n.loginBack,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthBrand(
                            tagline: l10n.loginTagline,
                            icon: AppAssets.authResetPassword,
                          ),
                          const SizedBox(height: 22),
                          AuthCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.forgotPasswordTitle,
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: AuthStyle.forestDark,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.forgotPasswordSubtitle,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AuthStyle.forest.withValues(
                                        alpha: 0.82,
                                      ),
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
                                  AuthTextField(
                                    controller: _emailController,
                                    label: l10n.loginEmail,
                                    assetIcon: AppAssets.authMail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.send,
                                    validator: (value) =>
                                        _validateEmail(context, value),
                                    onFieldSubmitted: (_) => _handleReset(),
                                  ),
                                  const SizedBox(height: 18),
                                  AuthPrimaryButton(
                                    label: l10n.forgotPasswordSendSignal,
                                    iconAsset: AppAssets.authSend,
                                    isLoading: _isLoading,
                                    onPressed: _handleReset,
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
            ),
          ),
        ),
      ),
    );
  }
}
