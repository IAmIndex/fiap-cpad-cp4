import 'package:flutter/material.dart';

class AppColors {
  static const foreground = Color(0xFF9381FF);
  static const background = Color(0xFF2C2C29);
  static const surface = Color(0xFFEEEBFF);
  static const darkAccent = Color(0xFF580E20);
  static const accent = Color(0xFFE34A6F);
  static const success = Color(0xFF3DDC97);
  static const warning = Color(0xFFFFC857);
}

class AppTheme {
  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.foreground,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.foreground : const Color(0xFF6048BD),
          onPrimary: isDark ? AppColors.background : Colors.white,
          secondary: isDark ? const Color(0xFFFF8CA7) : const Color(0xFFAB2649),
          surface: isDark ? const Color(0xFF363633) : Colors.white,
          onSurface: isDark ? AppColors.surface : AppColors.background,
          onSurfaceVariant: isDark
              ? const Color(0xFFCBC7D7)
              : const Color(0xFF605B6A),
          surfaceContainerHighest: isDark
              ? const Color(0xFF42423E)
              : AppColors.surface,
          outlineVariant: isDark
              ? const Color(0xFF555550)
              : const Color(0xFFDDD9E7),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.background
          : const Color(0xFFF7F7FA),
      visualDensity: VisualDensity.standard,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      textTheme: _withoutLetterSpacing(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        counterStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorMaxLines: 3,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static TextTheme _withoutLetterSpacing(TextTheme text) {
    TextStyle? compact(TextStyle? style) => style?.copyWith(letterSpacing: 0);
    return TextTheme(
      displayLarge: compact(text.displayLarge),
      displayMedium: compact(text.displayMedium),
      displaySmall: compact(text.displaySmall),
      headlineLarge: compact(text.headlineLarge),
      headlineMedium: compact(text.headlineMedium),
      headlineSmall: compact(text.headlineSmall),
      titleLarge: compact(text.titleLarge),
      titleMedium: compact(text.titleMedium),
      titleSmall: compact(text.titleSmall),
      bodyLarge: compact(text.bodyLarge),
      bodyMedium: compact(text.bodyMedium),
      bodySmall: compact(text.bodySmall),
      labelLarge: compact(text.labelLarge),
      labelMedium: compact(text.labelMedium),
      labelSmall: compact(text.labelSmall),
    );
  }
}
