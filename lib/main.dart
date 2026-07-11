import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'config/theme/theme_controller.dart';
import 'config/localization/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'di/di.dart';
import 'core/network/api_client.dart';
import 'core/utils/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await dotenv.load(fileName: ".env");
  await initDependencies();
  await ThemeController.instance.init();
  await LocaleController.instance.init();
  runApp(const EcoGridApp());
}

class EcoGridApp extends StatelessWidget {
  const EcoGridApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance.themeModeNotifier,
        ThemeController.instance.platformBrightnessRevision,
        LocaleController.instance.language,
      ]),
      builder: (context, _) {
        final currentThemeMode = ThemeController.instance.currentThemeMode;
        return MaterialApp(
          navigatorKey: ApiClient.navigatorKey,
          scaffoldMessengerKey: snackbarKey,
          title: 'EcoGrid Intelligence',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          locale: LocaleController.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
