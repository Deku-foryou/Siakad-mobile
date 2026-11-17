import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Theme light & dark Material 3 dengan palet SIAKAD.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppColors.seed);
  static ThemeData get dark => _build(Brightness.dark, AppColors.seedDark);

  static ThemeData _build(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 26,
      ),
      headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      titleLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
      labelLarge: const TextStyle(fontSize: 15),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
