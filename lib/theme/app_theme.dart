import 'package:flutter/material.dart';

/// Design tokens and ThemeData for the Warm Pastel Bento system.
class AppColors {
  const AppColors._();

  // Base surfaces
  static const Color background = Color(0xFFFFF9EB);
  static const Color surface = Color(0xFFFFF9EB);
  static const Color surfaceBright = Color(0xFFFFF9EB);
  static const Color surfaceDim = Color(0xFFE0DAC4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFBF3DD);
  static const Color surfaceContainer = Color(0xFFF5EED8);
  static const Color surfaceContainerHigh = Color(0xFFEFE8D2);
  static const Color surfaceContainerHighest = Color(0xFFE9E2CD);
  static const Color surfaceVariant = Color(0xFFE9E2CD);

  // Foreground / Ink
  static const Color onSurface = Color(0xFF1E1C0E);
  static const Color onBackground = Color(0xFF1E1C0E);
  static const Color onSurfaceVariant = Color(0xFF4A4640);
  static const Color inverseSurface = Color(0xFF343122);
  static const Color inverseOnSurface = Color(0xFFF8F1DA);
  static const Color outline = Color(0xFF7B766F);
  static const Color outlineVariant = Color(0xFFCCC5BD);

  // Primary (Obsidian Ink)
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1C1B1A);
  static const Color onPrimaryContainer = Color(0xFF868382);
  static const Color primaryFixed = Color(0xFFE6E2DF);

  // Secondary (Coral Sunset)
  static const Color secondary = Color(0xFFA13F25);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFF8667);
  static const Color onSecondaryContainer = Color(0xFF741F07);
  static const Color secondaryFixed = Color(0xFFFFDBD2);
  static const Color onSecondaryFixed = Color(0xFF3C0800);

  // Tertiary (Morning Sunlight)
  static const Color tertiary = Color(0xFF6F5D00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFC1AA4D);
  static const Color onTertiaryContainer = Color(0xFF4C3F00);
  static const Color tertiaryFixed = Color(0xFFFCE27D);
  static const Color onTertiaryFixed = Color(0xFF221B00);

  // Supporting Bento Pastels from DESIGN.md
  static const Color sageMeadow = Color(0xFFBDDDB8);
  static const Color onSageMeadow = Color(0xFF1B3518);
  static const Color periwinkleSky = Color(0xFFBACEEB);
  static const Color onPeriwinkleSky = Color(0xFF132A47);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double margin = 16;
  static const double lg = 20;
  static const double marginMd = 24;
  static const double xl = 32;
  static const double gutter = 12;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double standard = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double full = 9999;
}

class AppTypography {
  const AppTypography._();

  static const List<String> _displayFallback = [
    'Plus Jakarta Sans',
    'Inter',
    'Roboto',
    'sans-serif',
  ];

  static const List<String> _monoFallback = [
    'Space Grotesk',
    'Plus Jakarta Sans',
    'monospace',
  ];

  static const TextStyle headlineXl = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 52 / 48,
    letterSpacing: -1.44,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineXlMobile = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 40 / 36,
    letterSpacing: -1.08,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 36 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 28 / 24,
    letterSpacing: -0.48,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.18,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: _displayFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: _monoFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 16 / 13,
    letterSpacing: 0.26,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: _monoFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.44,
    color: AppColors.onSurfaceVariant,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.headlineXl,
        displayMedium: AppTypography.headlineXlMobile,
        headlineLarge: AppTypography.headlineLg,
        headlineMedium: AppTypography.headlineMd,
        headlineSmall: AppTypography.headlineSm,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTypography.bodySm.copyWith(
          color: AppColors.onPrimary,
        ),
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
