import 'package:flutter/material.dart';

import 'app_icon.dart';

/// A transparent touch target for Walkamon PNG controls.
///
/// The artwork is rendered directly. This widget deliberately adds no card,
/// circle, border, shadow, or permanent fill behind the PNG.
class AssetOnlyIconButton extends StatelessWidget {
  const AssetOnlyIconButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.icon,
    this.asset,
    this.buttonSize = 48,
    this.assetSize = 40,
    this.color,
  }) : assert(icon != null || asset != null);

  final VoidCallback? onPressed;
  final String semanticLabel;
  final IconData? icon;
  final String? asset;
  final double buttonSize;
  final double assetSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final overlayColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.black.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return Colors.black.withValues(alpha: 0.04);
      }
      return Colors.transparent;
    });

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(
            width: buttonSize,
            height: buttonSize,
          ),
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: overlayColor,
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          icon: ExcludeSemantics(
            child: AppIcon(icon, asset: asset, size: assetSize, color: color),
          ),
        ),
      ),
    );
  }
}
