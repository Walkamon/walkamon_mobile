import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/change_password_error_translator.dart';
import '../../data/repositories/change_password_screen_repository.dart';
import '../../widgets/common/error_message_widget.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ChangePasswordScreenRepository _repository =
      ChangePasswordScreenRepository();

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  String? _errorMessage;
  bool _success = false;
  FocusNode _currentPasswordFocus = FocusNode();
  FocusNode _newPasswordFocus = FocusNode();
  FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Mật khẩu hiện tại không được để trống.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Mật khẩu mới không được để trống.';
    }
    if (trimmed.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới.';
    }
    if (trimmed != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _repository.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      setState(() {
        _success = true;
      });
      return;
    }

    setState(() {
      _errorMessage = translateChangePasswordError(
        response.message.isNotEmpty
            ? response.message
            : 'Đổi mật khẩu thất bại. Vui lòng thử lại.',
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

    if (_success) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 96, color: primary),
                  const SizedBox(height: 24),
                  Text(
                    'Đổi mật khẩu thành công!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mật khẩu của bạn đã được cập nhật an toàn. Vui lòng sử dụng mật khẩu mới ở lần đăng nhập sau.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedForeground,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Quay lại cài đặt'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 24,
                                  color: primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đổi mật khẩu',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cập nhật mật khẩu để bảo vệ tài khoản của bạn',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (_errorMessage != null) ...[
                              ErrorMessageWidget(message: _errorMessage!),
                              const SizedBox(height: 20),
                            ],
                            _buildPasswordField(
                              label: 'Mật khẩu hiện tại',
                              controller: _currentPasswordController,
                              hintText: 'Nhập mật khẩu hiện tại của bạn',
                              obscureText: !_showCurrentPassword,
                              focusNode: _currentPasswordFocus,
                              onToggle: () {
                                setState(() {
                                  _showCurrentPassword = !_showCurrentPassword;
                                });
                              },
                              validator: _validateCurrentPassword,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: 'Mật khẩu mới',
                              controller: _newPasswordController,
                              hintText: 'Nhập mật khẩu mới của bạn',
                              obscureText: !_showNewPassword,
                              focusNode: _newPasswordFocus,
                              onToggle: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                              validator: _validateNewPassword,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: 'Xác nhận mật khẩu mới',
                              controller: _confirmPasswordController,
                              hintText: 'Xác nhận mật khẩu mới của bạn',
                              obscureText: !_showNewPassword,
                              focusNode: _confirmPasswordFocus,
                              onToggle: null,
                              validator: _validateConfirmPassword,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleChangePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLoading
                                      ? const Color(0xFFA7B7AF)
                                      : primary,
                                  foregroundColor: _isLoading
                                      ? Colors.grey[600]
                                      : onPrimary,
                                  disabledBackgroundColor: const Color(
                                    0xFFA7B7AF,
                                  ),
                                  disabledForegroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text('Lưu thay đổi'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    required VoidCallback? onToggle,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: focusNode.hasFocus
                    ? const Color(0xFF7ED957)
                    : Theme.of(context).colorScheme.outline,
                width: focusNode.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: focusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7ED957).withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 3,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              focusNode: focusNode,
              validator: validator,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.65),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
                suffixIcon: onToggle != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: onToggle,
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 22,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
