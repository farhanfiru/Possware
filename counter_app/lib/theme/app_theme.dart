import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Burgundy / Wine Red (from Owner Dashboard)
  static const Color primaryBurgundy = Color(0xFF7A1C28);
  static const Color primaryDark = Color(0xFF5E121D);
  static const Color primaryLight = Color(0xFF9E2A3A);
  static const Color primarySubtle = Color(0xFFFBF0F1);

  // Backgrounds & Canvas
  static const Color scaffoldBg = Color(0xFFFAF8F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEFEBE8);
  static const Color cardBorderHover = Color(0xFFDFD7D1);

  // Text & Neutrals
  static const Color textDark = Color(0xFF1F1C1D);
  static const Color textSecondary = Color(0xFF6B6461);
  static const Color textMuted = Color(0xFF9E9692);

  // Functional Accents
  static const Color cashGreen = Color(0xFF15803D);
  static const Color cashGreenLight = Color(0xFFDCFCE7);
  static const Color gpayBlue = Color(0xFF2563EB);
  static const Color gpayBlueLight = Color(0xFFDBEAFE);
  static const Color splitPurple = Color(0xFF7C3AED);
  static const Color splitPurpleLight = Color(0xFFF3E8FF);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryBurgundy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBurgundy,
        primary: primaryBurgundy,
        secondary: cashGreen,
        surface: surfaceWhite,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textDark, fontWeight: FontWeight.w800),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: textDark, fontWeight: FontWeight.w700),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textDark, fontWeight: FontWeight.w700),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: cardBorder, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBurgundy, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
