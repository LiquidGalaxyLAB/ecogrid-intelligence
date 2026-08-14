import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:showcaseview/showcaseview.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'config/theme/theme_controller.dart';
import 'config/localization/locale_controller.dart';
import 'core/constants/api_constants.dart';
import 'domain/repository/api_key_repository.dart';
import 'l10n/app_localizations.dart';
import 'di/di.dart';
import 'core/network/api_client.dart';
import 'core/utils/globals.dart';
import 'service/tour_service.dart';
import 'presentation/components/tour_skip_pill.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Load .env if present (existing users / local dev). New users can skip
  // this entirely and configure API keys via Settings → General → API Keys.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env file doesn't exist — that's fine, keys come from secure storage.
  }
  await initDependencies();

  // Hydrate runtime API key cache from secure storage so that all services
  // (GeminiRestApiService, AuthInterceptor, etc.) read the correct keys.
  await _hydrateApiKeys();

  await ThemeController.instance.init();
  await LocaleController.instance.init();
  runApp(const EcoGridApp());
}

/// Reads API keys from secure storage and populates [ApiConstants]' runtime
/// cache. Falls back to .env values if secure storage is empty (handled
/// internally by [ApiKeyRepository]).
Future<void> _hydrateApiKeys() async {
  try {
    final repo = sl<ApiKeyRepository>();
    final geminiKey = await repo.getGeminiApiKey();
    final mapsKey = await repo.getGoogleMapsApiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      ApiConstants.setGeminiApiKey(geminiKey);
    }
    if (mapsKey != null && mapsKey.isNotEmpty) {
      ApiConstants.setGoogleMapsApiKey(mapsKey);
    }
  } catch (e) {
    debugPrint('[EcoGrid] Failed to hydrate API keys: $e');
  }
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
