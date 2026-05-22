/// Application-wide configuration constants.
/// API keys are injected via --dart-define at build time.
class AppConfig {
  AppConfig._();

  // ─── App Identity ────────────────────────────────────
  static const String appName = 'EcoGrid Intelligence';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-Driven Climate Resilience Analysis for Global Energy Infrastructure';

  // ─── API Keys (injected via --dart-define) ──────────
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // ─── API Endpoints ──────────────────────────────────
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';
  static const String openMeteoArchive = '$openMeteoBaseUrl/archive';

  // ─── LG Defaults ────────────────────────────────────
  static const int lgDefaultPort = 22;
  static const String lgDefaultUsername = 'lg';
  static const String lgKmlPath = '/var/www/html/kml/';
  static const String lgQueryFile = '/tmp/query.txt';
  static const String lgFlyToFile = '/tmp/query.txt';
  static const int lgScreenCount = 5;

  // ─── Timeouts ───────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration sshTimeout = Duration(seconds: 15);
  static const Duration sshHeartbeatInterval = Duration(seconds: 30);

  // ─── Gemini Model ───────────────────────────────────
  static const String geminiModel = 'gemini-1.5-flash';
}
