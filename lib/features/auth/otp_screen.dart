import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/common/egg_shape.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

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
      _controllers.every((controller) => controller.text.trim().length == 1);

  bool get _isOtpDigitsOnly => _controllers.every(
    (controller) => RegExp(r'^\d$').hasMatch(controller.text.trim()),
  );

  String? _otpErrorMessage() {
    final errors = <String>[];
    if (!_isOtpComplete) {
      errors.add('OTP phải nhập đủ 4 ô.');
    }
    if (!_isOtpDigitsOnly) {
      errors.add('OTP chỉ được nhập số.');
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

  void _handleVerify() {
    final errorMessage = _otpErrorMessage();
    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: primary, size: 24),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Mật Mã Thức Tỉnh',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nhập 4 con số ma thuật đã được gửi đến hòm thư của bạn',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: mutedForeground,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_controllers.length, (
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: EggOtpField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    primary: primary,
                                    textStyle: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: primary,
                                        ),
                                    onChanged: (value) =>
                                        _handleChange(index, value),
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
                              onPressed: _handleVerify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                textStyle: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Xác Nhận Thức Tỉnh'),
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Gửi lại phép thuật',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
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
}
