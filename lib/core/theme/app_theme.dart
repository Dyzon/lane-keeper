import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF6B9080); // Calm Green
  static const Color background = Color(0xFFF6FFF8); // Off-white/Minty
  static const Color textCharcoal = Color(0xFF333333);
  static const Color accentMint = Color(0xFFA4C3B2);
  static const Color errorRed = Color(0xFFE07A5F);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        background: background,
        surface: Colors.white,
        onSurface: textCharcoal,
        primary: primaryGreen,
        secondary: accentMint,
        error: errorRed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textCharcoal,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          color: textCharcoal,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textCharcoal,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textCharcoal,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textCharcoal,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            color: textCharcoal, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: textCharcoal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
    );
  }
}
