import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_controller.dart';
import 'design_constants.dart';

class AppTheme {
  AppTheme._();
  static Color get background => ThemeController.instance.isDarkMode
      ? DesignConstants.darkBackground
      : DesignConstants.lightBackground;
  static Color get surface => ThemeController.instance.isDarkMode
      ? DesignConstants.darkElevatedSurface
      : DesignConstants.lightElevatedSurface;
  static Color get surfaceLight => ThemeController.instance.isDarkMode
      ? DesignConstants.darkCardSurface
      : DesignConstants.lightCardSurface;
  static Color get cardBackground => ThemeController.instance.isDarkMode
      ? DesignConstants.darkCardSurface
      : DesignConstants.lightCardSurface;
  static Color get cardBorder => ThemeController.instance.isDarkMode
      ? DesignConstants.darkBorder
      : DesignConstants.lightBorder;
  static Color get primary => ThemeController.instance.isDarkMode
      ? DesignConstants.primary
      : DesignConstants.lightPrimary;
  static Color get secondary => ThemeController.instance.isDarkMode
      ? DesignConstants.secondary
      : DesignConstants.lightSecondary;
  static Color get recentSearchIconColor => primary;
  static Color get recentSearchLeftBorderColor => secondary;
  static LinearGradient get primaryGradient =>
      ThemeController.instance.isDarkMode
      ? DesignConstants.singleGradient
      : DesignConstants.lightGradient;
  static LinearGradient get backgroundGradient => LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color riskLow = DesignConstants.riskLow;
  static const Color riskMedium = DesignConstants.riskMedium;
  static const Color riskHigh = DesignConstants.riskHigh;
  static const Color riskCritical = Color(0xFFFF3B3B);
  static Color get textPrimary => ThemeController.instance.isDarkMode
      ? DesignConstants.darkPrimaryText
      : DesignConstants.lightPrimaryText;
  static Color get textSecondary => ThemeController.instance.isDarkMode
      ? DesignConstants.darkSecondaryText
      : DesignConstants.lightSecondaryText;
  static Color get textMuted => ThemeController.instance.isDarkMode
      ? DesignConstants.darkMutedText
      : DesignConstants.lightMutedText;
  static const Color divider = Color(0xFF1E293B);
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF00E5A0);
  static const Color connectedGreen = DesignConstants.lgConnected;
  static const double radiusSmall = DesignConstants.borderRadiusSmall;
  static const double radiusMedium = DesignConstants.borderRadiusMedium;
  static const double radiusLarge = DesignConstants.borderRadiusLarge;
  static const double radiusXL = 24.0;
  static const double radiusFull = DesignConstants.borderRadiusPill;
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
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
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(
      color: cardBorder.withValues(alpha: 0.5),
      width: 1,
      strokeAlign: BorderSide.strokeAlignOutside,
    ),
  );
  static BoxDecoration get sheetDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: cardBorder, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 24,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ],
  );
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final bg = isDark
        ? DesignConstants.darkBackground
        : DesignConstants.lightBackground;
    final surf = isDark
        ? DesignConstants.darkElevatedSurface
        : DesignConstants.lightElevatedSurface;
    final surfLight = isDark
        ? DesignConstants.darkCardSurface
        : DesignConstants.lightCardSurface;
    final borderColor = isDark
        ? DesignConstants.darkBorder
        : DesignConstants.lightBorder;
    final textPrim = isDark
        ? DesignConstants.darkPrimaryText
        : DesignConstants.lightPrimaryText;
    final textSec = isDark
        ? DesignConstants.darkSecondaryText
        : DesignConstants.lightSecondaryText;
    final themePrimary = isDark
        ? DesignConstants.primary
        : DesignConstants.lightPrimary;
    final themeSecondary = isDark
        ? DesignConstants.secondary
        : DesignConstants.lightSecondary;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: themePrimary,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: themePrimary,
              secondary: themeSecondary,
              surface: surf,
              surfaceContainerHighest: surfLight,
              error: error,
              onPrimary: Color(0xFF0A0E1A),
              onSecondary: Color(0xFF0A0E1A),
              onSurface: textPrim,
              onError: textPrim,
              outline: borderColor,
            )
          : ColorScheme.light(
              primary: themePrimary,
              secondary: themeSecondary,
              surface: surf,
              surfaceContainerHighest: surfLight,
              error: error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: textPrim,
              onError: textPrim,
              outline: borderColor,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrim,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrim),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: themePrimary,
          foregroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          textStyle: labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSec,
          side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfLight,
        selectedColor: themePrimary.withValues(alpha: 0.15),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        labelStyle: bodySmall,
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surf,
        indicatorColor: themePrimary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfLight,
        contentTextStyle: bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: themePrimary,
        linearTrackColor: surfLight,
      ),
    );
  }
}
