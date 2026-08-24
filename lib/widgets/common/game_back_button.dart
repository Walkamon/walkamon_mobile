import 'package:flutter/material.dart';

import 'asset_only_icon_button.dart';

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
    return AssetOnlyIconButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      icon: Icons.arrow_back_rounded,
      buttonSize: buttonSize,
      assetSize: iconSize,
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
