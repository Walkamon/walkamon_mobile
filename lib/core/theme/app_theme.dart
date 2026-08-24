import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static WidgetStateProperty<Color?> _stateColor({
    required Color enabled,
    required Color disabled,
  }) {
    return WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? disabled : enabled,
    );
  }

  static ButtonStyle _filledButtonStyle(bool isDark) {
    final background = isDark ? AppColors.darkLife : AppColors.buttonGreen;
    final foreground = isDark
        ? AppColors.darkTextOutline
        : AppColors.buttonText;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
      backgroundColor: _stateColor(
        enabled: background,
        disabled: background.withValues(alpha: 0.48),
      ),
      foregroundColor: _stateColor(
        enabled: foreground,
        disabled: foreground.withValues(alpha: 0.68),
      ),
      overlayColor: WidgetStatePropertyAll(
        AppColors.woodDeep.withValues(alpha: 0.12),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
      shape: WidgetStatePropertyAll(
        StadiumBorder(
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
            width: 2,
          ),
        ),
      ),
      backgroundBuilder: (context, states, child) => CustomPaint(
        painter: _LeafButtonPainter(
          color: states.contains(WidgetState.disabled)
              ? AppColors.olive.withValues(alpha: 0.42)
              : AppColors.oliveDeep,
          pressed: states.contains(WidgetState.pressed),
        ),
        child: child,
      ),
    );
  }

  static ButtonStyle _elevatedButtonStyle(bool isDark) {
    final background = isDark ? AppColors.darkLife : AppColors.buttonYellow;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
      backgroundColor: _stateColor(
        enabled: background,
        disabled: background.withValues(alpha: 0.46),
      ),
      foregroundColor: _stateColor(
        enabled: isDark ? AppColors.darkTextOutline : AppColors.buttonText,
        disabled: (isDark ? AppColors.darkTextOutline : AppColors.buttonText)
            .withValues(alpha: 0.65),
      ),
      overlayColor: WidgetStatePropertyAll(
        AppColors.woodDeep.withValues(alpha: 0.12),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
      shape: WidgetStatePropertyAll(
        StadiumBorder(
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle(bool isDark) {
    final background = isDark ? AppColors.darkMuted : AppColors.buttonSecondary;
    final foreground = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      backgroundColor: _stateColor(
        enabled: background,
        disabled: background.withValues(alpha: 0.45),
      ),
      foregroundColor: _stateColor(
        enabled: foreground,
        disabled: foreground.withValues(alpha: 0.52),
      ),
      overlayColor: WidgetStatePropertyAll(
        AppColors.woodDeep.withValues(alpha: 0.1),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? AppColors.wood.withValues(alpha: 0.45)
              : (isDark ? AppColors.darkBorder : AppColors.woodDeep),
          width: 2,
        ),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    );
  }

  static ButtonStyle _textButtonStyle(bool isDark) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      foregroundColor: WidgetStatePropertyAll(
        isDark ? AppColors.darkForeground : AppColors.woodDeep,
      ),
      overlayColor: WidgetStatePropertyAll(
        AppColors.leaf.withValues(alpha: 0.16),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Quicksand',
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightPrimaryForeground,
        secondary: AppColors.lightAccent,
        onSecondary: AppColors.lightPrimaryForeground,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightForeground,
        outline: AppColors.lightBorder,
      ),
      dividerColor: AppColors.lightMuted,
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(false),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(false),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(false),
      ),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle(false)),
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'Quicksand',
        bodyColor: AppColors.lightForeground,
        displayColor: AppColors.lightForeground,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Quicksand',
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkAccent,
        onSecondary: AppColors.darkPrimaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        outline: AppColors.darkBorder,
      ),
      dividerColor: AppColors.darkMuted,
      filledButtonTheme: FilledButtonThemeData(style: _filledButtonStyle(true)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(true),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(true),
      ),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle(true)),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Quicksand',
        bodyColor: AppColors.darkForeground,
        displayColor: AppColors.darkForeground,
      ),
    );
  }
}

class _LeafButtonPainter extends CustomPainter {
  const _LeafButtonPainter({required this.color, required this.pressed});

  final Color color;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 104 || size.height < 36) return;

    final fill = Paint()
      ..color = color.withValues(alpha: pressed ? 0.72 : 0.9)
      ..style = PaintingStyle.fill;
    final edge = Paint()
      ..color = AppColors.woodDeep.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void leaf(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: 15, height: 8);
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    final centerY = size.height / 2;
    leaf(Offset(8, centerY - 5), -0.55);
    leaf(Offset(8, centerY + 5), 0.55);
    leaf(Offset(size.width - 8, centerY - 5), 0.55);
    leaf(Offset(size.width - 8, centerY + 5), -0.55);
  }

  @override
  bool shouldRepaint(covariant _LeafButtonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pressed != pressed;
}
