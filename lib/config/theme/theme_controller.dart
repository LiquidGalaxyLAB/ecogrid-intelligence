import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with WidgetsBindingObserver {
  static final ThemeController instance = ThemeController._();
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );
  final ValueNotifier<int> platformBrightnessRevision = ValueNotifier<int>(0);
  ThemeController._() {
    WidgetsBinding.instance.addObserver(this);
  }
  ThemeMode get currentThemeMode => themeModeNotifier.value;
  bool get isDarkMode {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    return dispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.dark.index;
    themeModeNotifier.value =
        themeIndex >= 0 && themeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeIndex]
        : ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  @override
  void didChangePlatformBrightness() {
    if (themeModeNotifier.value == ThemeMode.system) {
      platformBrightnessRevision.value++;
    }
  }
}
