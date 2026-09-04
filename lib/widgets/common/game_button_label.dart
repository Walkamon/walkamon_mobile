import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// High-contrast game button text with the brown outline used by the UI kit.
class GameButtonLabel extends StatelessWidget {
  const GameButtonLabel(
    this.text, {
    super.key,
    this.fontSize = 17,
    this.letterSpacing = 0.2,
    this.color,
    this.outlineColor,
    this.outlineWidth = 3,
    this.maxLines = 1,
  });

  final String text;
  final double fontSize;
  final double letterSpacing;
  final Color? color;
  final Color? outlineColor;
  final double outlineWidth;
  final int maxLines;

  TextStyle _style({Color? color, Paint? foreground}) {
    return TextStyle(
      color: color,
      foreground: foreground,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
      // Quicksand's Vietnamese tone marks extend beyond a 1.0 line box.
      // Keep a little vertical leading so labels such as "Nhận" are not
      // clipped while retaining the compact game-button proportions.
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = isDark
        ? AppColors.darkForeground
        : (color ?? AppColors.buttonText);
    final resolvedOutline = isDark
        ? AppColors.darkTextOutline
        : (outlineColor ?? AppColors.buttonBorder);
    final shadowOffset = (outlineWidth / 2).clamp(0.0, 1.25).toDouble();
    // A single text node keeps hit testing, semantics and widget tests
    // deterministic while the small four-way shadow preserves the game
    // label's outlined appearance without duplicating the glyph tree.
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: _style(color: resolvedColor).copyWith(
        shadows: shadowOffset == 0
            ? const <Shadow>[]
            : [
                Shadow(offset: Offset(shadowOffset, 0), color: resolvedOutline),
                Shadow(
                  offset: Offset(-shadowOffset, 0),
                  color: resolvedOutline,
                ),
                Shadow(offset: Offset(0, shadowOffset), color: resolvedOutline),
                Shadow(
                  offset: Offset(0, -shadowOffset),
                  color: resolvedOutline,
                ),
              ],
      ),
    );
  }
}
