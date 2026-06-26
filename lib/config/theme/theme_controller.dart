import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  ThemeMode get currentThemeMode => themeModeNotifier.value;

  // Checks if the active mode is dark based on ThemeMode and system settings
  bool get isDarkMode {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    // Default to dark if system isn't available, or check platform dispatcher
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    return dispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt('theme_mode') ?? 0; // 0: system, 1: light, 2: dark
    themeModeNotifier.value = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeModeNotifier.value == mode) return;

    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}
