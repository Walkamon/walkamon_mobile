import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

/// Shared back control dimensions and styling for portrait game screens.
class GameBackButton extends StatelessWidget {
  const GameBackButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
  });

  static const double buttonSize = 48;
  static const double iconSize = 32;
  static const double screenLeft = 20;
  static const double screenTop = 8;

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: buttonSize,
      child: Material(
        color: AppColors.authCard,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.woodDeep, width: 2),
        ),
        elevation: 3,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: semanticLabel,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          iconSize: iconSize,
          icon: const AppIcon(
            Icons.arrow_back_rounded,
            size: iconSize,
            color: AppColors.inkDark,
          ),
        ),
      ),
    );
  }
}

/// Places [GameBackButton] consistently inside a full-screen [Stack].
class PositionedGameBackButton extends StatelessWidget {
  const PositionedGameBackButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: GameBackButton.screenTop,
      left: GameBackButton.screenLeft,
      child: SafeArea(
        child: GameBackButton(
          onPressed: onPressed,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
