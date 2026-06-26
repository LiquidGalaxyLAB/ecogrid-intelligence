import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All API endpoints, keys, and timeouts.
class ApiConstants {
  ApiConstants._();

  // ─── API Keys (loaded via dotenv) ────────────────────
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── Open-Meteo Endpoints ────────────────────────────
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';
  static const String openMeteoArchive =
      'https://archive-api.open-meteo.com/v1/archive';

  // ─── Gemini AI ────────────────────────────────────────
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';

  /// Fast model for structured insights (Insight Card, Scenario, Regional, Trend).
  static const String geminiInsightModel = 'gemini-3.1-flash-lite';

  /// Larger model for conversational chat (Plant AI Chat).
  static const String geminiChatModel = 'gemini-3.1-flash-lite';

  // ─── Timeouts ────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 60);
}
