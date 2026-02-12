import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeVariant { calm, vibrant, neutral }

class AppThemes {
  static ThemeData baseTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A84FF)),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
      splashFactory: InkRipple.splashFactory,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  // Per-variant accent/background helpers
  static Color accentFor(AppThemeVariant v) {
    switch (v) {
      case AppThemeVariant.calm:
        return const Color(0xFF0A8F86); // teal-green (sea)
      case AppThemeVariant.vibrant:
        return const Color(0xFF0066CC); // deep ocean blue
      case AppThemeVariant.neutral:
        return const Color(0xFF5A4636); // earth/bark
    }
  }

  static Color backgroundFor(AppThemeVariant v) {
    switch (v) {
      case AppThemeVariant.calm:
        return const Color(0xFFF0FBFA); // very light sea tint
      case AppThemeVariant.vibrant:
        return const Color(0xFFE8F4FF); // light ocean tint
      case AppThemeVariant.neutral:
        return const Color(0xFFFAF6F2); // light sand/beige
    }
  }
}
