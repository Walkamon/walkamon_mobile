import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
      textTheme: GoogleFonts.quicksandTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: AppColors.lightForeground,
          displayColor: AppColors.lightForeground,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
      textTheme: GoogleFonts.quicksandTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.darkForeground,
          displayColor: AppColors.darkForeground,
        ),
      ),
    );
  }
}
