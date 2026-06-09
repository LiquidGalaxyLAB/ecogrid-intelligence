// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:ecogrid_intelligence/core/constants/api_constants.dart';
import 'package:ecogrid_intelligence/data/data_sources/remote/ai_data_source.dart';

/// Groq implementation of [AIDataSource].
///
/// Uses the OpenAI-compatible REST API at https://api.groq.com/openai/v1.
/// Two models are used:
/// - [ApiConstants.groqInsightModel] for structured insights (fast, cheap).
/// - [ApiConstants.groqChatModel] for conversational chat (deeper reasoning).
class GroqRemoteDataSource implements AIDataSource {
  final Dio _dio;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static int _globalCallCount = 0;
  static DateTime? _lastCallTime;

  GroqRemoteDataSource({required Dio dio}) : _dio = dio;

  // ─── Cooldown ─────────────────────────────────────────

  void _enforceCooldown() {
    if (_lastCallTime != null) {
      final elapsed = DateTime.now().difference(_lastCallTime!);
      if (elapsed.inSeconds < 3) {
        throw Exception(
          'Please wait at least 3 seconds before requesting another insight.',
        );
      }
    }
    _lastCallTime = DateTime.now();
    _globalCallCount++;
    _logger.w('🌐 Global AI Call Count: $_globalCallCount');
  }

  // ─── Insight Generation (fast model) ──────────────────

  @override
  Future<String> generateInsight({
    required String prompt,
    required String source,
  }) async {
    return _call(
      model: ApiConstants.groqInsightModel,
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      source: source,
      temperature: 0.7,
      maxTokens: 1024,
    );
  }

  // ─── Chat (large model) ───────────────────────────────

  @override
  Future<String> sendChatMessage({
    required List<Map<String, String>> history,
    required String message,
    required String source,
  }) async {
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];

    return _call(
      model: ApiConstants.groqChatModel,
      messages: messages,
      source: source,
      temperature: 0.7,
      maxTokens: 1024,
    );
  }

  // ─── Internal HTTP Call ───────────────────────────────

  Future<String> _call({
    required String model,
    required List<Map<String, String>> messages,
    required String source,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    _enforceCooldown();

    final totalChars = messages.fold<int>(
      0,
      (sum, m) => sum + (m['content']?.length ?? 0),
    );
    final approxTokens = totalChars ~/ 4;

    _logger.i(
      '🚀 Groq Request Initiated\n'
      'Source: $source\n'
      'Model: $model\n'
      'Prompt Approx Tokens: ~$approxTokens',
    );

    final apiKey = ApiConstants.groqApiKey;
    if (apiKey.isEmpty) {
      _logger.e('❌ Groq Request Failed: API key is missing.');
      throw Exception('Groq API key is missing. Please check your .env file.');
    }

    try {
      final startTime = DateTime.now();

      final response = await _dio.post(
        '${ApiConstants.groqBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      final duration = DateTime.now().difference(startTime);
      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;

      if (choices.isEmpty) {
        throw Exception('Groq returned empty choices.');
      }

      final content = choices[0]['message']['content'] as String? ?? '';

      _logger.i(
        '✅ Groq Request Succeeded\n'
        'Source: $source\n'
        'Model: $model\n'
        'Duration: ${duration.inMilliseconds}ms\n'
        'Response Length: ${content.length} chars',
      );

      return content.isNotEmpty ? content : 'Unable to generate analysis.';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      _logger.e(
        '❌ Groq Request Failed\n'
        'Source: $source\n'
        'HTTP Status: $statusCode\n'
        'Error: $body',
      );

      if (statusCode == 429) {
        throw Exception(
          'Rate limit exceeded (429). Please try again in a few moments.',
        );
      }
      throw Exception('Groq API error ($statusCode): $body');
    } catch (e) {
      _logger.e('❌ Groq Request Failed\nSource: $source\nError: $e');
      throw Exception('Failed to connect to Groq API: $e');
    }
  }
}
