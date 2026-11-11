import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double fieldRadius = 14;
  static const double controlHeight = 52;
  static const double screenPadding = 20;

  static ThemeData get light => _build(AppColors.lightScheme);
  static ThemeData get dark => _build(AppColors.darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness, useMaterial3: true);
    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    TextStyle grotesk(double size, {double? height, double spacing = 0}) =>
        GoogleFonts.spaceGrotesk(
          fontSize: size,
          height: height,
          letterSpacing: spacing,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        );

    final textTheme = inter.copyWith(
      headlineMedium: grotesk(28, height: 1.15, spacing: -0.56),
      titleLarge: grotesk(20),
      bodyLarge: inter.bodyLarge?.copyWith(fontSize: 15),
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 12),
      labelLarge: inter.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: inter.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
    );

    OutlineInputBorder border(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius));

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        disabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(controlHeight),
          shape: buttonShape,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.6),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(controlHeight),
          shape: buttonShape,
          foregroundColor: scheme.tertiary,
          side: BorderSide(color: scheme.outline, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.tertiary,
          textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
