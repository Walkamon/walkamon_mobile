import 'package:flutter/material.dart';

import 'package:walkamon_mobile/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/register_screen_error_translator.dart';
import '../../data/repositories/forgot_password_screen_repository.dart';
import '../../widgets/common/error_message_widget.dart';

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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.loginEmailRequired;
    }
    if (!RegExp(r"^[\w.+\-]+@[\w\-]+\.[\w\-.]+$").hasMatch(trimmed)) {
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

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _authRepository.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

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
      setState(() {
        _successMessage = l10n.forgotPasswordResetSent;
      });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                          l10n.forgotPasswordTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.forgotPasswordSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          ErrorMessageWidget(message: _errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _successMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                size: 22,
                                color: primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.send,
                                  validator: (value) => _validateEmail(context, value),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.loginEmail,
                                    hintStyle: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withAlpha((0.6 * 255).round()),
                                          fontWeight: FontWeight.w600,
                                        ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onFieldSubmitted: (_) => _handleReset(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
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
                              : Text(l10n.forgotPasswordSendSignal),
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
