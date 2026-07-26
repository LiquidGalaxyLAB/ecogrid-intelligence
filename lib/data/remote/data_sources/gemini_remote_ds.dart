import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/resources/network_state.dart';
import '../api_services/gemini_api_service.dart';
import 'ai_data_source.dart';

class GeminiRemoteDataSource implements AIDataSource {
  final GeminiApiService _apiService;
  final Logger _logger = Logger();
  static DateTime? _lastCallTime;
  static const _maxRetries = 4;
  static const _retryDelay = Duration(seconds: 5);

  GeminiRemoteDataSource({required GeminiApiService apiService})
    : _apiService = apiService;

  @override
  Stream<NetworkState<String>> generateInsight({
    required String prompt,
    required String source,
  }) => _call(
    model: ApiConstants.geminiInsightModel,
    messages: [
      {'role': 'user', 'content': prompt},
    ],
    source: source,
  );

  @override
  Stream<NetworkState<String>> sendChatMessage({
    required List<Map<String, String>> history,
    required String message,
    required String source,
  }) => _call(
    model: ApiConstants.geminiChatModel,
    messages: [
      ...history,
      {'role': 'user', 'content': message},
    ],
    source: source,
  );

  Stream<NetworkState<String>> _call({
    required String model,
    required List<Map<String, String>> messages,
    required String source,
  }) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    final previous = _lastCallTime;
    if (previous != null && DateTime.now().difference(previous).inSeconds < 3) {
      yield NetworkFailure(
        exception: Exception(
          'Please wait at least 3 seconds before requesting another insight.',
        ),
      );
      return;
    }
    _lastCallTime = DateTime.now();
    Exception? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final content = await _apiService.createChatCompletion(
          model: model,
          messages: messages,
          temperature: 0.7,
          maxTokens: 1024,
        );
        yield NetworkSuccess(content);
        return;
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status != null && status >= 400 && status < 500 && status != 429) {
          yield NetworkFailure(
            exception: Exception(
              'Gemini API error ($status): ${error.response?.data}',
            ),
            statusCode: status,
          );
          return;
        }
        if (status == 429) {
          lastError = Exception('Gemini API rate limit exceeded (429). Please wait a moment and try again.');
        } else {
          lastError = Exception('Gemini network error: ${error.message}');
        }
      } on SocketException catch (error) {
        lastError = Exception('Network error: $error');
      } catch (error, stackTrace) {
        _logger.w(
          'Gemini request failed from $source',
          error: error,
          stackTrace: stackTrace,
        );
        lastError = error is Exception ? error : Exception('$error');
      }
      if (attempt < _maxRetries) {
        final delay = lastError.toString().contains('429')
            ? Duration(seconds: 3 * attempt)
            : _retryDelay;
        await Future<void>.delayed(delay);
      }
    }
    yield NetworkFailure(
      exception: lastError ?? Exception('Gemini request failed.'),
    );
  }
}
