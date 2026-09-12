import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/localization/translation_resolver.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/change_password_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/game_back_button.dart';

/// Settings-only password change. Uses the authenticated PUT endpoint; it must
/// never invoke Forgot Password, request an OTP, or replace the login session.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.repository});

  final ChangePasswordScreenRepository? repository;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _newPasswordFocus = FocusNode();
  late final ChangePasswordScreenRepository _repository;
  bool _busy = false;
  bool _complete = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ChangePasswordScreenRepository();
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _newPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    final l10n = AppLocalizations.of(context);
    final password = value ?? '';
    if (password.isEmpty) return l10n.changePasswordNewPasswordRequired;
    if (password.length < 6) return l10n.changePasswordNewPasswordMinLength;
    if (password == _currentPassword.text) return l10n.changePasswordDifferent;
    // Match ChangePasswordRequestValidator; the server remains authoritative.
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[\W_]').hasMatch(password)) {
      return l10n.changePasswordRequirements;
    }
    return null;
  }

  String _responseError(ApiResponse<void> response) {
    final l10n = AppLocalizations.of(context);
    final message = response.message.toLowerCase();
    if (response.errorCode == 'AUTH_CURRENT_PASSWORD_INVALID' ||
        message.contains('current password is invalid')) {
      return l10n.apiErrorAuthCurrentPassword;
    }
    if (message.contains('new password must be different')) {
      return l10n.changePasswordDifferent;
    }
    if (message.contains('new password must')) {
      return l10n.changePasswordRequirements;
    }
    return TranslationResolver.resolveResponse(context, response);
  }

  Future<void> _submit() async {
    if (_busy || _complete) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // Passwords are opaque values. Do not trim, normalize, log or store them.
      final response = await _repository.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      if (response.success) {
        _currentPassword.clear();
        _newPassword.clear();
        setState(() => _complete = true);
      } else {
        setState(() => _error = _responseError(response));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).changePasswordFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = dark ? theme.colorScheme.onSurface : AppColors.woodDeep;
    return Stack(
      children: [
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 76, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 100),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: dark
                            ? theme.colorScheme.surface
                            : AppColors.authCard,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: dark
                              ? theme.colorScheme.outline
                              : AppColors.wood,
                          width: 2,
                        ),
                      ),
                      child: _complete
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    l10n.changePasswordSuccessTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: foreground,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.changePasswordSuccessSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(48, 56),
                                    ),
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    child: Text(
                                      l10n.changePasswordBackToSettings,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.changePasswordTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.changePasswordSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _passwordField(
                                    key: const ValueKey(
                                      'change-password-current',
                                    ),
                                    controller: _currentPassword,
                                    label: l10n.changePasswordCurrentPassword,
                                    hint:
                                        l10n.changePasswordCurrentPasswordHint,
                                    hidden: _hideCurrent,
                                    toggle: () => setState(
                                      () => _hideCurrent = !_hideCurrent,
                                    ),
                                    action: TextInputAction.next,
                                    submitted: (_) =>
                                        _newPasswordFocus.requestFocus(),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? l10n.changePasswordCurrentPasswordRequired
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _passwordField(
                                    key: const ValueKey('change-password-new'),
                                    controller: _newPassword,
                                    label: l10n.changePasswordNewPassword,
                                    hint: l10n.changePasswordNewPasswordHint,
                                    hidden: _hideNew,
                                    toggle: () =>
                                        setState(() => _hideNew = !_hideNew),
                                    focusNode: _newPasswordFocus,
                                    action: TextInputAction.done,
                                    submitted: (_) => _submit(),
                                    validator: _validateNew,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.changePasswordRequirements,
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  FilledButton(
                                    key: const ValueKey('change-password-save'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(48, 56),
                                    ),
                                    onPressed: _busy ? null : _submit,
                                    child: _busy
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              l10n.changePasswordSave,
                                              textAlign: TextAlign.center,
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
        PositionedGameBackButton(
          semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _passwordField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool hidden,
    required VoidCallback toggle,
    required TextInputAction action,
    required FormFieldValidator<String> validator,
    required ValueChanged<String> submitted,
    FocusNode? focusNode,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      enabled: !_busy,
      obscureText: hidden,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: action,
      validator: validator,
      onFieldSubmitted: submitted,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorMaxLines: 4,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        suffixIcon: IconButton(
          tooltip: hidden ? l10n.showPassword : l10n.hidePassword,
          onPressed: _busy ? null : toggle,
          icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
