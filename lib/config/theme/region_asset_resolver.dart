import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/config/theme/theme_controller.dart';

class RegionAssetResolver {
  static String getRegionImage(String regionId, [ThemeMode? mode]) {
    final isDark = mode != null
        ? (mode == ThemeMode.dark ||
              (mode == ThemeMode.system &&
                  WidgetsBinding
                          .instance
                          .platformDispatcher
                          .platformBrightness ==
                      Brightness.dark))
        : ThemeController.instance.isDarkMode;
    final folder = isDark ? 'dark' : 'light';

    return 'assets/images/regions/$folder/$regionId.png';
  }
}
