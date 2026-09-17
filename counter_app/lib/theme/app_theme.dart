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

  // Typography Presets (Plus Jakarta Sans)
  static TextStyle font({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textDark,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.2,
      height: height,
    );
  }

  static TextStyle heading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.4,
    );
  }

  static TextStyle price({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w900,
    Color color = textDark,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static ThemeData get theme {
    final baseFont = GoogleFonts.plusJakartaSans();
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: baseFont.fontFamily,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryBurgundy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBurgundy,
        primary: primaryBurgundy,
        secondary: primaryBurgundy,
        surface: surfaceWhite,
      ),
      textTheme: baseTextTheme.apply(
        fontFamily: baseFont.fontFamily,
        bodyColor: textDark,
        displayColor: textDark,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w900, letterSpacing: -1.0),
        displayMedium: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        titleLarge: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleMedium: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleSmall: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyMedium: GoogleFonts.plusJakartaSans(color: textSecondary, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.plusJakartaSans(color: textMuted, fontWeight: FontWeight.w500),
        labelLarge: GoogleFonts.plusJakartaSans(color: textDark, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.3,
        ),
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
            letterSpacing: -0.2,
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
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
