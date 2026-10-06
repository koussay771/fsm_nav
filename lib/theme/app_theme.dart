// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary     = Color(0xFF005C99);   // FSM deep blue
  static const Color accent      = Color(0xFF00C2FF);   // Cyan accent
  static const Color routeColor  = Color(0xFFFF2D55);   // Navigation route
  static const Color startColor  = Color(0xFF34C759);   // Start marker green
  static const Color destColor   = Color(0xFFFF3B30);   // Dest marker red
  static const Color surface     = Color(0xFF1C2333);   // Dark surface
  static const Color surfaceCard = Color(0xFF242D42);   // Card background
  static const Color onSurface   = Color(0xFFE8EDF5);   // Text on dark
  static const Color highlight   = Color(0x440099FF);   // Tapped feature highlight

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: onSurface,
    ),
    scaffoldBackgroundColor: const Color(0xFF111827),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: onSurface,
      displayColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: surfaceCard,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A2235),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E3A55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E3A55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
      labelStyle: const TextStyle(color: accent),
    ),
  );
}
