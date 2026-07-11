import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_endpoints.dart';

/// Transport contract for Gemini-compatible chat-completion providers.
/// Alternative model providers can implement this without changing data sources.
abstract interface class GeminiApiService {
  Future<String> createChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
  });
}

class GeminiRestApiService implements GeminiApiService {
  final Dio _dio;
  GeminiRestApiService({required Dio dio}) : _dio = dio;

  @override
  Future<String> createChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final apiKey = ApiConstants.geminiApiKey;
    if (apiKey.isEmpty) throw StateError('Gemini API key is missing.');
    final response = await _dio.post(
      ApiEndpoints.geminiChatCompletions,
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Authorization': 'Bearer $apiKey'},
      ),
      data: {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>)
      throw const FormatException('Invalid Gemini response.');
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const FormatException('Gemini returned no choices.');
    }
    final message = (choices.first as Map)['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }
    return content;
  }
}
