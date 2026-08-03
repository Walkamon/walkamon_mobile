import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

abstract final class AuthStyle {
  static const forest = Color(0xFF395C3B);
  static const forestDark = Color(0xFF213E2B);
  static const cream = Color(0xFFFFFBF1);
  static const gold = Color(0xFFE9B86A);
  static const rust = Color(0xFFA96536);
}

class AuthGardenScaffold extends StatelessWidget {
  const AuthGardenScaffold({
    super.key,
    required this.child,
    this.backgroundAsset = AppAssets.authGarden,
  });

  final Widget child;
  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
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
        child,
      ],
    );
  }
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, required this.tagline, this.icon});

  final String tagline;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AuthStyle.cream.withValues(alpha: 0.91),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.wood, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334A3213),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(icon ?? AppAssets.authLoginSteps),
        ),
        const SizedBox(height: 10),
        Text(
          'WALKAMON',
          style: textTheme.titleLarge?.copyWith(
            color: AuthStyle.forestDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            shadows: const [Shadow(color: Colors.white70, blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AuthStyle.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AuthStyle.cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.wood, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2B472E),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.assetIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String assetIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AuthStyle.forestDark,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AuthStyle.forest.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(assetIcon, width: 28, height: 28),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.wood, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.wood, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.woodDeep, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB74A3A)),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconAsset,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? iconAsset;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.buttonGreen,
        foregroundColor: AppColors.buttonText,
        disabledBackgroundColor: AppColors.buttonGreen.withValues(alpha: 0.55),
        shape: const StadiumBorder(
          side: const BorderSide(color: AppColors.woodDeep, width: 2),
        ),
        elevation: 2,
        shadowColor: AuthStyle.forest.withValues(alpha: 0.35),
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
                  color: AuthStyle.cream,
                ),
              )
            : Row(
                key: const ValueKey('ready'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconAsset != null) ...[
                    Image.asset(iconAsset!, width: 30, height: 30),
                    const SizedBox(width: 10),
                  ],
                  GameButtonLabel(label),
                ],
              ),
      ),
    );
  }
}

class AuthRoundIconButton extends StatelessWidget {
  const AuthRoundIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameBackButton(semanticLabel: semanticLabel, onPressed: onPressed);
  }
}

class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background = isError
        ? const Color(0xFFFFE8DE)
        : const Color(0xFFE7F7DF);
    final border = isError ? const Color(0xFFE4A18D) : const Color(0xFFA8D796);
    final text = isError ? const Color(0xFF7A342A) : const Color(0xFF2F6331);
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: text, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
