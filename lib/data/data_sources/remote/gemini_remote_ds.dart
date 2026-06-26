// ignore_for_file: prefer_initializing_formals

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import 'ai_data_source.dart';

/// Gemini implementation of [AIDataSource].
///
/// Uses the OpenAI-compatible REST API at https://generativelanguage.googleapis.com/v1beta/openai.
/// Two models are used:
/// - [ApiConstants.geminiInsightModel] for structured insights (fast, cheap).
/// - [ApiConstants.geminiChatModel] for conversational chat (deeper reasoning).
///
/// Includes automatic retry logic (up to 3 attempts) to handle transient
/// connection failures on Android emulators and slow networks.
class GeminiRemoteDataSource implements AIDataSource {
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

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  GeminiRemoteDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.geminiBaseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 90),
            sendTimeout: const Duration(seconds: 30),
          ),
        );

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
      model: ApiConstants.geminiInsightModel,
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
      model: ApiConstants.geminiChatModel,
      messages: messages,
      source: source,
      temperature: 0.7,
      maxTokens: 1024,
    );
  }

  // ─── Internal HTTP Call with Retry ────────────────────

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
      '🚀 Gemini Request Initiated\n'
      'Source: $source\n'
      'Model: $model\n'
      'Prompt Approx Tokens: ~$approxTokens',
    );

    final apiKey = ApiConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      _logger.e('❌ Gemini Request Failed: API key is missing.');
      throw Exception('Gemini API key is missing. Please check your .env file.');
    }

    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      if (attempt > 1) {
        _logger.w(
          '🔄 Gemini Retry Attempt $attempt/$_maxRetries\n'
          'Source: $source\n'
          'Waiting ${_retryDelay.inSeconds}s before retry...',
        );
        await Future.delayed(_retryDelay);
      }

      try {
        final startTime = DateTime.now();

        final response = await _dio.post(
          '/chat/completions',
          options: Options(
            receiveTimeout: const Duration(seconds: 90),
            sendTimeout: const Duration(seconds: 30),
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
          throw Exception('Gemini returned empty choices.');
        }

        final content = choices[0]['message']['content'] as String? ?? '';

        _logger.i(
          '✅ Gemini Request Succeeded\n'
          'Source: $source\n'
          'Model: $model\n'
          'Attempt: $attempt/$_maxRetries\n'
          'Duration: ${duration.inMilliseconds}ms\n'
          'Response Length: ${content.length} chars',
        );

        return content.isNotEmpty ? content : 'Unable to generate analysis.';
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;

        _logger.e(
          '❌ Gemini Request Failed (Attempt $attempt/$_maxRetries)\n'
          'Source: $source\n'
          'HTTP Status: $statusCode\n'
          'Type: ${e.type}\n'
          'Message: ${e.message}\n'
          'Error: $body',
        );

        // Do NOT retry on 4xx errors (auth, bad request, rate limit)
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          if (statusCode == 429) {
            throw Exception(
              'Rate limit exceeded (429). Please try again in a few moments.',
            );
          }
          throw Exception('Gemini API error ($statusCode): $body');
        }

        // Retry on connection/timeout errors (statusCode == null)
        lastError = Exception('Gemini API error ($statusCode): $body');
      } on SocketException catch (e) {
        _logger.e(
          '❌ Gemini Network Error (Attempt $attempt/$_maxRetries)\n'
          'Source: $source\n'
          'Error: $e',
        );
        lastError = Exception('Network error: $e');
      } catch (e) {
        _logger.e(
          '❌ Gemini Request Failed (Attempt $attempt/$_maxRetries)\n'
          'Source: $source\n'
          'Error: $e',
        );
        lastError = Exception('Failed to connect to Gemini API: $e');
      }
    }

    _logger.e(
      '❌ Gemini All $_maxRetries Attempts Failed\n'
      'Source: $source',
    );
    throw lastError ?? Exception('Gemini request failed after $_maxRetries attempts.');
  }
}
