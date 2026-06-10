import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email không được để trống.';
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$').hasMatch(v)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Mật khẩu không được để trống.';
    return null;
  }

  // ── Business logic ────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    // 1. Kiểm tra validate form nếu có
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<GameStateProvider>();

    // 2. Truyền text từ các Controller vào hàm login
    final success = await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // 3. Điều hướng nếu thành công hoặc hiển thị SnackBar nếu thất bại
    if (success) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
      ); // hoặc route màn hình chính của bạn
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Đăng nhập thất bại.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            // Center content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 80,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // h1
                        Text(
                          'Chào mừng trở lại!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mở cuốn nhật ký của bạn và tiếp tục cuộc hành trình cùng Lumina',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Email field ──────────────────────────────
                        _PillField(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.directions_walk,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          cardColor: cardColor,
                          primary: primary,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // ── Password field ───────────────────────────
                        _PillField(
                          controller: _passwordController,
                          hint: 'Mật khẩu',
                          icon: Icons.key_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          cardColor: cardColor,
                          primary: primary,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 8),

                        // ── Forgot password ──────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/auth/forgot'),
                            style: TextButton.styleFrom(
                              foregroundColor: mutedForeground,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                            child: const Text(
                              'Quên mật mã bí mật?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Submit button ─────────────────────────────
                        _TapScaleButton(
                          onPressed: _handleLogin,
                          backgroundColor: primary,
                          foregroundColor: onPrimary,
                          label: 'Bắt Đầu Hành Trình',
                        ),
                        const SizedBox(height: 40),

                        // ── Register link ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chưa phải là lữ hành giả?',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedForeground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/auth/register',
                              ),
                              child: Text(
                                'Đăng ký tại đây',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Back button với Opacity & Soft Shadow ───────────────────────
            // ── Back button Tối Giản  ──
            Positioned(
              top: 16,
              left:
                  16, // Nhích vào một chút nhìn sẽ cân đối hơn khi không còn khung tròn
              child: SafeArea(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    ),
                    // Sử dụng drop-shadow trực tiếp lên biểu tượng để tạo chiều sâu mờ
                    icon: Icon(
                      Icons.arrow_back,
                      color: primary.withValues(
                        alpha: 0.9,
                      ), // Giảm gắt màu nhẹ nhàng
                      size:
                          24, // Tăng nhẹ size icon lên 24 nhìn sẽ đứng form hơn
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
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

// ── Pill-shaped input field (Đã tinh chỉnh bóng mịn, bỏ border) ─────────────────

class _PillField extends StatelessWidget {
  const _PillField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.cardColor,
    required this.primary,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color cardColor;
  final Color primary;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor.withValues(
          alpha: 0.95,
        ), // Kết hợp Opacity nền nhẹ nhàng
        borderRadius: BorderRadius.circular(32),
        // Đã BỎ Border thô hoàn toàn
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Đổ bóng siêu dịu
            offset: const Offset(0, 4),
            blurRadius: 16, // Tăng độ nhòe cho bóng mịn hơn
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primary.withValues(alpha: 0.85),
          ), // Giảm gắt màu icon
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              validator: validator,
              onFieldSubmitted: onFieldSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tap-scale submit button (Bóng đổ mịn tự nhiên) ───────────────────────────

class _TapScaleButton extends StatefulWidget {
  const _TapScaleButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              // Lớp bóng mịn diện rộng để tạo chiều sâu cao cấp
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.15),
                offset: const Offset(0, 8),
                blurRadius: 20,
              ),
              // Lớp bóng định hình khối sát chân nút
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Material(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17, // Giảm nhẹ 1px nhìn sẽ thanh thoát hơn hẳn
                    fontWeight: FontWeight.w700,
                    color: widget.foregroundColor,
                    letterSpacing: 0.5,
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
