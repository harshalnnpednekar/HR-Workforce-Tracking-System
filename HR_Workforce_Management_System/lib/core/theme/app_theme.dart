import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme provides the theme configuration for the application.
/// It defines both light and dark themes with corporate colors.
class AppTheme {
  // Corporate Palette
  static const Color primaryBlue = Color(0xFF003366);
  static const Color emeraldGreen = Color(0xFF28A745);

  // Premium Aesthetic Palette
  static const Color premiumNavy = Color(0xFF0A192F);
  static const Color softBlue = Color(0xFFE6F0FF);
  static const Color royalPurple = Color(0xFF6366F1);
  static const Color slateGrey = Color(0xFF64748B);
  static const Color accentCyan = Color(0xFF06B6D4);

  /// Returns the Light Theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: royalPurple,
        primary: royalPurple,
        secondary: accentCyan,
        surface: Colors.white,
        onSurface: premiumNavy,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: royalPurple, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 2,
          shadowColor: royalPurple.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    );
  }

  /// Returns the Dark Theme for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: emeraldGreen,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
