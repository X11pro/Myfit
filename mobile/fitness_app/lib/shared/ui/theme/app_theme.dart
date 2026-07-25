import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0B0D12);
  static const backgroundSecondary = Color(0xFF11131A);
  static const surface = Color(0xFF171A22);
  static const surfaceMuted = Color(0xFF1D212B);
  static const border = Color(0xFF2A303C);
  static const primary = Color(0xFF8DC3F2);
  static const success = Color(0xFF44B573);
  static const warning = Color(0xFFD8A55D);
  static const danger = Color(0xFFCF6679);

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
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
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        elevation: 0,
        centerTitle: true,
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
        indicatorColor: primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : Colors.white70,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
