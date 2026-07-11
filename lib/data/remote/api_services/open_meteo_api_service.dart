import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';

class OpenMeteoApiService {
  final Dio _dio;
  OpenMeteoApiService({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> getForecast(Map<String, dynamic> query) =>
      _get(ApiEndpoints.openMeteoForecast, query);

  Future<Map<String, dynamic>> getArchive(Map<String, dynamic> query) => _get(
    ApiEndpoints.openMeteoArchive,
    query,
    maxRetries: 3,
    timeout: const Duration(seconds: 60),
  );

  Future<Map<String, dynamic>> _get(
    String url,
    Map<String, dynamic> query, {
    int maxRetries = 2,
    Duration? timeout,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _dio.get(
          url,
          queryParameters: query,
          options: timeout == null
              ? null
              : Options(receiveTimeout: timeout, sendTimeout: timeout),
        );
        if (response.data is! Map<String, dynamic>) {
          throw const FormatException('Invalid Open-Meteo response.');
        }
        return response.data as Map<String, dynamic>;
      } on DioException catch (error) {
        final retryable =
            error.response?.statusCode == 429 ||
            error.response?.statusCode == 503 ||
            error.response?.statusCode == 504;
        if (!retryable || attempt >= maxRetries) rethrow;
        await Future<void>.delayed(Duration(seconds: 5 * (attempt + 1)));
      }
    }
  }
}
