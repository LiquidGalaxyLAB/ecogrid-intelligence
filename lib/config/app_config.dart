import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide configuration constants.
/// API keys are loaded via flutter_dotenv from the .env file.
class AppConfig {
  AppConfig._();

  // ─── App Identity ────────────────────────────────────
  static const String appName = 'EcoGrid Intelligence';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-Driven Climate Resilience Analysis for Global Energy Infrastructure';

  // ─── API Keys (loaded via dotenv) ────────────────────
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── API Endpoints ──────────────────────────────────
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';
  static const String openMeteoArchive =
      'https://archive-api.open-meteo.com/v1/archive';

  // ─── Groq AI ────────────────────────────────────────
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';

  /// Fast model for structured insights (Insight Card, Scenario, Regional, Trend).
  static const String groqInsightModel = 'llama-3.1-8b-instant';

  /// Larger model for conversational chat (Plant AI Chat).
  static const String groqChatModel = 'llama-3.3-70b-versatile';

  // ─── LG Defaults ────────────────────────────────────
  static const int lgDefaultPort = 22;
  static const String lgDefaultUsername = 'lg';
  static const String lgKmlPath = '/var/www/html/kml/';
  static const String lgQueryFile = '/tmp/query.txt';
  static const String lgFlyToFile = '/tmp/query.txt';
  static const int lgScreenCount = 3;
  static const String lgMasterKmlFile = '/var/www/html/kml/kmls.kml';
  static const String lgDashboardHtmlFile = '/var/www/html/dashboard.html';
  static const String lgDashboardUrl = 'http://lg1:81/dashboard.html';

  // ─── Timeouts ───────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 25);
  static const Duration sshTimeout = Duration(seconds: 15);
  static const Duration sshHeartbeatInterval = Duration(seconds: 30);
}
