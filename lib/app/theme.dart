import 'package:flutter/material.dart';

class AppColors {
  static const foreground = Color(0xFF9381FF);
  static const background = Color(0xFF2C2C29);
  static const surface = Color(0xFFEEEBFF);
  static const darkAccent = Color(0xFF580E20);
  static const accent = Color(0xFFE34A6F);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.foreground,
      secondary: AppColors.accent,
      surface: AppColors.background,
    ),
    useMaterial3: true,
  );
}
