import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EcoGrid Intelligence Design System
/// Dark futuristic palette with emerald/teal accents
class AppTheme {
  AppTheme._();

  // ─── Core Colors ─────────────────────────────────────
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF0D1321);
  static const Color surfaceLight = Color(0xFF111827);
  static const Color cardBackground = Color(0xFF151C2C);
  static const Color cardBorder = Color(0xFF1E293B);

  // ─── Primary Accent ──────────────────────────────────
  static const Color primary = Color(0xFF00E5A0);
  static const Color primaryDark = Color(0xFF00B87A);
  static const Color primaryLight = Color(0xFF33EAAC);
  static const Color secondary = Color(0xFF00C9FF);

  // ─── Gradient ────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00C9FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1321)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x1A00E5A0), Color(0x0000E5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Risk Colors ─────────────────────────────────────
  static const Color riskLow = Color(0xFF00E5A0);
  static const Color riskMedium = Color(0xFFFFD700);
  static const Color riskHigh = Color(0xFFFF8C00);
  static const Color riskCritical = Color(0xFFFF3B3B);

  // ─── Text Colors ─────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF7B8CA6);
  static const Color textMuted = Color(0xFF4A5568);

  // ─── Misc ────────────────────────────────────────────
  static const Color divider = Color(0xFF1E293B);
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF00E5A0);
  static const Color connectedGreen = Color(0xFF00E676);

  // ─── Dimensions ──────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ─── Shadows ─────────────────────────────────────────
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> get subtleGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];

  // ─── Text Styles ─────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 1.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  // ─── Card Decoration ─────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: cardBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      );

  static BoxDecoration get cardDecorationGlow => BoxDecoration(
        color: cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: subtleGlow,
      );

  // ─── ThemeData ───────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: Color(0xFF0A0E1A),
          onSecondary: Color(0xFF0A0E1A),
          onSurface: textPrimary,
          onError: textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: headingMedium,
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: BorderSide(
              color: cardBorder.withValues(alpha: 0.5),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceLight.withValues(alpha: 0.5),
          hintStyle: bodyMedium.copyWith(color: textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusFull),
            borderSide: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusFull),
            borderSide: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusFull),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 0.5,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
}
