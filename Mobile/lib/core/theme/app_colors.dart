import 'package:flutter/material.dart';

/// Design tokens from design/DESIGN.md (gold theme).
class AppColors {
  AppColors._();

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    surface: Color(0xFFFAF8F3), // bg
    surfaceContainerHighest: Color(0xFFFFFFFF), // fields, cards
    onSurface: Color(0xFF14110A),
    onSurfaceVariant: Color(0xFF6B6454),
    outline: Color(0xFF8C8369), // input borders: 3.6:1 on bg (WCAG 1.4.11)
    outlineVariant: Color(0xFFD6CDB8), // decorative: cards, dividers
    primary: Color(0xFFD4A017),
    onPrimary: Color(0xFF1A1405),
    primaryContainer: Color(0xFFFBF1D4),
    onPrimaryContainer: Color(0xFF14110A),
    secondary: Color(0xFF0A7A53), // ok / connected dot (5:1 on bg)
    onSecondary: Colors.white,
    tertiary: Color(0xFF8A6100), // gold text on light backgrounds
    onTertiary: Colors.white,
    error: Color(0xFFC62828),
    onError: Colors.white,
    errorContainer: Color(0xFFFDECEC),
    onErrorContainer: Color(0xFF14110A),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    surface: Color(0xFF0E0C08),
    surfaceContainerHighest: Color(0xFF181510),
    onSurface: Color(0xFFF3EEE3),
    onSurfaceVariant: Color(0xFFA39A85),
    outline: Color(0xFF776C55), // input borders: 3.5:1 on field (WCAG 1.4.11)
    outlineVariant: Color(0xFF3B3425), // decorative: cards, dividers
    primary: Color(0xFFF5C542),
    onPrimary: Color(0xFF1A1405),
    primaryContainer: Color(0xFF2E2510),
    onPrimaryContainer: Color(0xFFF3EEE3),
    secondary: Color(0xFF3DDC97),
    onSecondary: Color(0xFF06261A),
    tertiary: Color(0xFFF5C542),
    onTertiary: Color(0xFF1A1405),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF2A0B0A),
    errorContainer: Color(0xFF3A1618),
    onErrorContainer: Color(0xFFF3EEE3),
  );
}
