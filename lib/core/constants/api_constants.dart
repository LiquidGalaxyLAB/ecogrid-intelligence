import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // ─── Runtime API-key cache ────────────────────────────────────────────────
  // Populated at startup from secure storage. Falls back to .env values so
  // that the app still works before migration or if secure storage fails.

  static String _geminiApiKey = '';

  /// Sets the runtime Gemini API key (called from main.dart at startup).
  static void setGeminiApiKey(String key) => _geminiApiKey = key;

  /// The Gemini API key – reads from runtime cache, falls back to .env.
  static String get geminiApiKey {
    if (_geminiApiKey.isNotEmpty) return _geminiApiKey;
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  // ─── Endpoints & config ───────────────────────────────────────────────────

  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';
  static const String openMeteoArchive =
      'https://archive-api.open-meteo.com/v1/archive';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiInsightModel = 'gemini-3.1-flash-lite';
  static const String geminiChatModel = 'gemini-3.1-flash-lite';
  static const Duration apiTimeout = Duration(seconds: 60);
}
