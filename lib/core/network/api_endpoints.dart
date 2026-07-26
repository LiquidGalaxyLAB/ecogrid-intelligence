import '../constants/api_constants.dart';

/// A single source of truth for every API endpoint URL used in the project.
///
/// Group endpoints by their remote service so it is obvious which base URL
/// they belong to. Prefer `const` values; compute dynamic segments at the
/// call-site using string interpolation.
///
/// These values intentionally mirror [ApiConstants] base URLs so that all
/// URL construction happens in one place.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // ─── Open-Meteo ─────────────────────────────────────────────────────────────

  /// Current weather forecast (temperature, humidity, wind, precipitation).
  static const String openMeteoForecast = ApiConstants.openMeteoForecast;

  /// Historical weather archive (returns daily aggregates).
  static const String openMeteoArchive = ApiConstants.openMeteoArchive;

  // ─── Gemini (native REST API) ──────────────────────────────────────────────

  /// Base URL for the Gemini REST API.
  static const String geminiBase = ApiConstants.geminiBaseUrl;

  /// Builds the native generateContent endpoint for a given model.
  static String geminiGenerateContent(String model) =>
      '$geminiBase/models/$model:generateContent';

  /// Chat completions endpoint (kept for backward compatibility).
  static const String geminiChatCompletions = '$geminiBase/openai/chat/completions';
}
