import 'package:flutter/material.dart';

class DesignConstants {
  // SURFACES — DARK THEME
  static const Color darkBackground = Color(0xFF06060C);
  static const Color darkCardSurface = Color(0xFF0D1117);
  static const Color darkElevatedSurface = Color(0xFF131920);
  static const Color darkBorder = Color(0xFF1E2A35);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFF8A9BAE);
  static const Color darkMutedText = Color(0xFF4A5568);

  // SURFACES — LIGHT THEME
  static const Color lightBackground = Color(0xFFF0F4FF);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightElevatedSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightPrimaryText = Color(0xFF0D1117);
  static const Color lightSecondaryText = Color(0xFF4A5568);
  static const Color lightMutedText = Color(0xFF64748B);

  // FIXED SEMANTIC COLORS — NEVER CHANGE WITH THEME
  static const Color lgConnected = Color(0xFF00C853);
  static const Color lgDisconnected = Color(0xFFFF1744);

  static const Color riskHigh = Color(0xFFFF3B30);
  static const Color riskMedium = Color(0xFFFF9500);
  static const Color riskLow = Color(0xFF34C759);

  static const Color fuelHydro = Color(0xFF2196F3);
  static const Color fuelNuclear = Color(0xFF00BCD4);
  static const Color fuelThermal = Color(0xFFFF5722);
  static const Color fuelSolar = Color(0xFFFFC107);
  static const Color fuelWind = Color(0xFF4CAF50);
  static const Color fuelGas = Color(0xFFF44336);
  static const Color fuelOther = Color(0xFF607D8B);

  // REGION FIXED UNDERLINE COLORS — NEVER CHANGE WITH THEME
  static const Color regionIndia = Color(0xFF00C853);
  static const Color regionEurope = Color(0xFF4A90D9);
  static const Color regionUsa = Color(0xFF4A90D9);
  static const Color regionChina = Color(0xFF7B8FD4);
  static const Color regionAfrica = Color(0xFFE8A44A);
  static const Color regionSpain = Color(0xFFE85D4A);

  // BORDER RADIUS
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusPill = 100.0;

  // SINGLE GRADIENT — used everywhere, same in both themes:
  static const Color primary = Color(0xFF00C8FF);
  static const Color secondary = Color(0xFF0066FF);

  static const LinearGradient singleGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // CONTEXT-AWARE HELPERS
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      _isDark(context) ? darkBackground : lightBackground;
  static Color cardSurface(BuildContext context) =>
      _isDark(context) ? darkCardSurface : lightCardSurface;
  static Color elevatedSurface(BuildContext context) =>
      _isDark(context) ? darkElevatedSurface : lightElevatedSurface;
  static Color border(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;
  static Color primaryText(BuildContext context) =>
      _isDark(context) ? darkPrimaryText : lightPrimaryText;
  static Color secondaryText(BuildContext context) =>
      _isDark(context) ? darkSecondaryText : lightSecondaryText;
  static Color mutedText(BuildContext context) =>
      _isDark(context) ? darkMutedText : lightMutedText;
}
