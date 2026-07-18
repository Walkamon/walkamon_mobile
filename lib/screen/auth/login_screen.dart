import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/login_screen_error_translator.dart';
import '../../data/datasources/remote/notification_datasource.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/fcm_service.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _forest = Color(0xFF395C3B);
  static const _forestDark = Color(0xFF213E2B);
  static const _cream = Color(0xFFFFFBF1);
  static const _gold = Color(0xFFE9B86A);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _obscurePassword = true;
  String? _inlineErrorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
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
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email không được để trống.';
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$').hasMatch(email)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Mật khẩu không được để trống.';
    return null;
  }

  Future<void> _handleLogin() async {
    final provider = context.read<GameStateProvider>();
    if (provider.isLoading) return;

    setState(() => _inlineErrorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (!success) {
      final rawError = provider.errorMessage ?? 'Đăng nhập thất bại.';
      final cleanError = rawError.replaceAll('Exception: ', '').trim();
      setState(() => _inlineErrorMessage = translateLoginError(cleanError));
      return;
    }

    try {
      final notificationRepository = NotificationRepositoryImpl(
        datasource: NotificationDatasourceImpl(ApiClient()),
      );
      unawaited(FCMService(notificationRepository).setupToken());
    } catch (error) {
      debugPrint('Không thể khởi tạo thông báo: $error');
    }

    final userId = provider.user?.id ?? '';
    if (userId.isNotEmpty && mounted) {
      await context.read<StepTrackingProvider>().startForUser(userId);
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<GameStateProvider, bool>(
      (provider) => provider.isLoading,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.authGarden,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x120F2819), Color(0x00FFF7E3), Color(0x38365525)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: _opacity,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                semanticLabel: 'Quay lại',
                                onPressed: () =>
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/',
                                      (route) => false,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildBrand(context),
                            const SizedBox(height: 22),
                            _buildLoginCard(context, isLoading),
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
      ],
    );
  }

  Widget _buildBrand(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cream.withValues(alpha: 0.91),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334A3213),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(AppAssets.authLoginSteps),
        ),
        const SizedBox(height: 10),
        Text(
          'WALKAMON',
          style: textTheme.titleLarge?.copyWith(
            color: _forestDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            shadows: const [Shadow(color: Colors.white70, blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mỗi bước chân, một phép màu',
          style: textTheme.bodyMedium?.copyWith(
            color: _forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isLoading) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2B472E),
            blurRadius: 32,
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
              'Chào mừng trở lại!',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: _forestDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tiếp tục hành trình cùng tinh linh Lumina của bạn.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: _forest.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (_inlineErrorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _inlineErrorMessage!),
            ],
            const SizedBox(height: 20),
            _ForestTextField(
              controller: _emailController,
              label: 'Email',
              assetIcon: AppAssets.authMail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            _ForestTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              assetIcon: AppAssets.authLock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _handleLogin(),
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Image.asset(
                  _obscurePassword
                      ? AppAssets.authVisibilityOff
                      : AppAssets.authVisibility,
                  width: 25,
                  height: 25,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pushNamed(context, '/auth/forgot'),
                style: TextButton.styleFrom(foregroundColor: _forest),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: _forest,
                foregroundColor: _cream,
                disabledBackgroundColor: _forest.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
                shadowColor: _forest.withValues(alpha: 0.35),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _cream,
                        ),
                      )
                    : Row(
                        key: const ValueKey('ready'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppAssets.authLoginSteps,
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'Chưa có tài khoản?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _forest.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/auth/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA96536),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ForestTextField extends StatelessWidget {
  const _ForestTextField({
    required this.controller,
    required this.label,
    required this.assetIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String assetIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF395C3B);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: Color(0xFF213E2B),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: forest.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(assetIcon, width: 28, height: 28),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8CDAE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8CDAE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _LoginScreenState._gold,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB74A3A)),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4A18D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFF9B3F32),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A342A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _LoginScreenState._cream.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: IconButton(
        tooltip: semanticLabel,
        onPressed: onPressed,
        color: _LoginScreenState._forestDark,
        icon: Icon(icon),
      ),
    );
  }
}
