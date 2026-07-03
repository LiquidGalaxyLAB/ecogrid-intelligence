import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';
  static const String openMeteoArchive =
      'https://archive-api.open-meteo.com/v1/archive';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai';
  static const String geminiInsightModel = 'gemini-3.1-flash-lite';
  static const String geminiChatModel = 'gemini-3.1-flash-lite';
  static const Duration apiTimeout = Duration(seconds: 60);
}
