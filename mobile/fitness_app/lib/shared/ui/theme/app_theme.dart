import 'package:flutter/material.dart';

class AppTheme {
  // 60-30-10: neutral canvas, charcoal structure and energetic orange actions.
  static const background = Color(0xFFF7F7F5);
  static const backgroundSecondary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F0ED);
  static const border = Color(0xFFDEDED8);
  static const charcoal = Color(0xFF202124);
  static const primary = Color(0xFFE6511E);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57C00);
  static const danger = Color(0xFFC62828);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: primary,
      tertiary: warning,
      error: danger,
      surface: surface,
      surfaceContainerHighest: surfaceMuted,
      outlineVariant: border,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: Typography.material2021().black.apply(
            bodyColor: charcoal,
            displayColor: charcoal,
          ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundSecondary,
        indicatorColor: primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : charcoal.withValues(alpha: 0.68),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : charcoal.withValues(alpha: 0.68),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
