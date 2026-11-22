import 'package:flutter/material.dart';

class AppTheme {
  // Neutral, layered surfaces give data and primary actions more prominence.
  static const background = Color(0xFF0B141D);
  static const backgroundSecondary = Color(0xFF131C25);
  static const surface = Color(0xFF172029);
  static const surfaceMuted = Color(0xFF222B34);
  static const border = Color(0xFF3F4944);
  static const charcoal = Color(0xFFDAE3F0);
  static const primary = Color(0xFF9EE8CC);
  static const onPrimary = Color(0xFF102218);
  static const success = Color(0xFF9EE8CC);
  static const secondary = Color(0xFFFFBA87);
  static const tertiary = Color(0xFFFFA5A5);
  static const neutral = Color(0xFF1C252E);
  static const warning = secondary;
  static const danger = tertiary;
  static const mutedText = Color(0xFFBEC9C3);

  static final panelShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
    side: const BorderSide(color: border),
  );

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: background,
      secondaryContainer: neutral,
      onSecondaryContainer: charcoal,
      tertiary: tertiary,
      onTertiary: background,
      tertiaryContainer: neutral,
      onTertiaryContainer: charcoal,
      error: danger,
      surface: surface,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: background,
      surfaceContainerLow: backgroundSecondary,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceMuted,
      surfaceContainerHighest: surfaceMuted,
      outline: border,
      outlineVariant: border,
      onSurface: charcoal,
      onSurfaceVariant: mutedText,
    );

    return ThemeData(
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      useMaterial3: true,
      canvasColor: surface,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
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
              letterSpacing: -.42,
            ),
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: panelShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
        titleTextStyle: const TextStyle(
          color: charcoal,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
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
