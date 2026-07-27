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

    // Convert OpenAI-style messages to native Gemini contents format
    final contents = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final role = msg['role'] == 'assistant' ? 'model' : 'user';
      contents.add({
        'role': role,
        'parts': [
          {'text': msg['content'] ?? ''}
        ],
      });
    }

    final url = ApiEndpoints.geminiGenerateContent(model);
    final response = await _dio.post(
      url,
      queryParameters: {'key': apiKey},
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 30),
      ),
      data: {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid Gemini response.');
    }

    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('Gemini returned no candidates.');
    }

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned no content.');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const FormatException('Gemini returned no parts.');
    }

    final text = (parts.first as Map<String, dynamic>)['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }

    return text;
  }
}
