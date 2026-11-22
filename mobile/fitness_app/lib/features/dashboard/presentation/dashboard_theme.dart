import 'package:flutter/material.dart';

class DashboardTheme {
  // Neutral, layered surfaces give data and primary actions more prominence.
  static const background = Color(0xFF0B141D);
  static const backgroundSecondary = Color(0xFF131C25);
  static const surface = Color(0xFF172029);
  static const surfaceMuted = Color(0xFF222B34);
  static const border = Color(0xFF3F4944);
  static const charcoal = Color(0xFFDAE3F0);
  static const primary = Color(0xFF9EE8CC);
  static const success = Color(0xFF9EE8CC);
  static const warning = Color(0xFFFCB885);
  static const danger = Color(0xFFFFB4AB);
  static const mutedText = Color(0xFFBEC9C3);

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: const Color(0xFF102218),
      secondary: warning,
      tertiary: warning,
      error: danger,
      surface: surface,
      surfaceContainerLow: backgroundSecondary,
      surfaceContainerHighest: surfaceMuted,
      outlineVariant: border,
      onSurface: charcoal,
      onSurfaceVariant: mutedText,
    );

    return ThemeData(
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: Typography.material2021()
          .white
          .apply(
            fontFamily: 'Inter',
            bodyColor: charcoal,
            displayColor: charcoal,
          )
          .copyWith(
            headlineMedium: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 36 / 28,
                letterSpacing: -.42),
            titleLarge: const TextStyle(
              color: charcoal,
              fontFamily: 'Plus Jakarta Sans',
              height: 28 / 22,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceMuted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: mutedText),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundSecondary,
        indicatorColor: primary.withValues(alpha: 0.18),
        height: 74,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : mutedText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : mutedText,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
