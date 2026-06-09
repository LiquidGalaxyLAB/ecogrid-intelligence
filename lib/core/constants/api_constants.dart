import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All API endpoints, keys, and timeouts.
class ApiConstants {
  ApiConstants._();

  // ─── API Keys (loaded via dotenv) ────────────────────
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── Open-Meteo Endpoints ────────────────────────────
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

  // ─── Timeouts ────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 25);
}
