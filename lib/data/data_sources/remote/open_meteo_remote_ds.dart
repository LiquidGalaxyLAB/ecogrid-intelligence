import 'package:dio/dio.dart';
import 'package:ecogrid_intelligence/core/constants/api_constants.dart';
import 'package:ecogrid_intelligence/core/exception/exceptions.dart';

/// Remote data source for Open-Meteo API.
class OpenMeteoRemoteDataSource {
  final Dio dio;

  OpenMeteoRemoteDataSource({required this.dio});

  /// Helper with retry logic
  Future<Response> _getWithRetry(
    String url,
    Map<String, dynamic> queryParameters, {
    int maxRetries = 2,
    Duration? timeout,
  }) async {
    int retryCount = 0;
    while (true) {
      try {
        return await dio.get(
          url,
          queryParameters: queryParameters,
          options: timeout != null
              ? Options(receiveTimeout: timeout, sendTimeout: timeout)
              : null,
        );
      } on DioException catch (e) {
        // Only retry on 429 Too Many Requests or 504 Gateway Timeout
        if ((e.response?.statusCode == 429 ||
                e.response?.statusCode == 504 ||
                e.response?.statusCode == 503) &&
            retryCount < maxRetries) {
          retryCount++;
          // Exponential backoff: 5s, 10s, 15s
          final delay = Duration(seconds: 5 * retryCount);
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  /// Fetch current weather + anomaly data for a location.
  Future<Map<String, dynamic>> fetchCurrentClimate(
    double lat,
    double lon,
  ) async {
    try {
      final response = await _getWithRetry(ApiConstants.openMeteoForecast, {
        'latitude': lat,
        'longitude': lon,
        'current':
            'temperature_2m,relative_humidity_2m,precipitation,'
            'wind_speed_10m,weather_code',
        'daily':
            'temperature_2m_max,temperature_2m_min,'
            'precipitation_sum,wind_speed_10m_max',
        'timezone': 'auto',
        'forecast_days': 7,
      });

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException(
        message: 'Open-Meteo returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch climate data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetch recent historical climate data (up to ~92 days back).
  /// Uses the forecast API which has generous rate limits.
  Future<Map<String, dynamic>> fetchHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _getWithRetry(ApiConstants.openMeteoForecast, {
        'latitude': lat,
        'longitude': lon,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'daily':
            'temperature_2m_mean,temperature_2m_max,temperature_2m_min,'
            'precipitation_sum,wind_speed_10m_max',
        'timezone': 'auto',
      });

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException(
        message: 'Open-Meteo returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch historical data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetch long-term archive climate data (multi-year, e.g. 2010-2024).
  /// Uses the archive API which has stricter rate limits — only call on user demand.
  Future<Map<String, dynamic>> fetchArchiveClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _getWithRetry(
        ApiConstants.openMeteoArchive,
        {
          'latitude': lat,
          'longitude': lon,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
          'daily':
              'temperature_2m_mean,temperature_2m_max,temperature_2m_min,'
              'precipitation_sum,wind_speed_10m_max',
          'timezone': 'auto',
        },
        maxRetries: 3,
        timeout: const Duration(
          seconds: 60,
        ), // Archive requests are huge (16 years), allow 60s
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException(
        message: 'Open-Meteo archive returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch archive data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
