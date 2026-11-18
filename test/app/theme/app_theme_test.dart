import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/theme/app_colors.dart';
import 'package:siakad_mobile/app/theme/app_spacing.dart';
import 'package:siakad_mobile/app/theme/app_theme.dart';

/// Design system: light/dark theme konsisten (Material 3, palet SIAKAD).
void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test('memakai Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('brightness light & skema dari seed teal', () {
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(
        theme.colorScheme.primary,
        isNot(AppTheme.dark.colorScheme.primary),
      );
    });

    test('surface/background diisi scheme (bukan hitam/putih keras)', () {
      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
    });

    test('filled/outlined button tinggi minimal 48 (target sentuh)', () {
      final filled = theme.filledButtonTheme.style?.minimumSize;
      final outlined = theme.outlinedButtonTheme.style?.minimumSize;
      expect(filled?.resolve({})?.height ?? 0, greaterThanOrEqualTo(48));
      expect(outlined?.resolve({})?.height ?? 0, greaterThanOrEqualTo(48));
    });

    test('input decoration memakai border radius konsisten', () {
      final border =
          theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius.resolve(TextDirection.ltr).topLeft.x, 12);
    });

    test('card elevation 0 + radius 12 (konsisten)', () {
      expect(theme.cardTheme.elevation, 0);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 12);
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark;

    test('brightness dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('text color memakai onSurface scheme (bukan hitam)', () {
      expect(theme.textTheme.bodyMedium?.color, theme.colorScheme.onSurface);
    });

    test('dark mode tetap memakai Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('AppColors', () {
    test('semantic colors terdefinisi & konsisten light/dark (hex sama)', () {
      expect(AppColors.success, const Color(0xFF15803D));
      expect(AppColors.warning, const Color(0xFFB45309));
      expect(AppColors.error, const Color(0xFFB91C1C));
      expect(AppColors.info, const Color(0xFF1D4ED8));
    });
  });

  group('Kontras teks (light & dark)', () {
    double luminanceContrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final lighter = la >= lb ? la : lb;
      final darker = la >= lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('teks body vs background memenuhi rasio wajar (> 4.5)', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final ratio = luminanceContrast(
          theme.colorScheme.onSurface,
          theme.scaffoldBackgroundColor,
        );
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    });
  });

  test('spacing scale kelipatan 4 dan radius 12', () {
    expect(AppSpacing.xxs, 4);
    expect(AppSpacing.xs, 8);
    expect(AppSpacing.sm, 12);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
    expect(AppSpacing.xxl, 48);
    expect(AppSpacing.radius, 12);
  });
}
