import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/resources/network_state.dart';

class OpenMeteoRemoteDataSource {
  final Dio dio;
  OpenMeteoRemoteDataSource({required this.dio});
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
        if ((e.response?.statusCode == 429 ||
                e.response?.statusCode == 504 ||
                e.response?.statusCode == 503) &&
            retryCount < maxRetries) {
          retryCount++;
          final delay = Duration(seconds: 5 * retryCount);
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  Stream<NetworkState<Map<String, dynamic>>> fetchCurrentClimate(
    double lat,
    double lon,
  ) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    try {
      final response = await _getWithRetry(ApiEndpoints.openMeteoForecast, {
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
        yield NetworkSuccess(response.data as Map<String, dynamic>);
        return;
      }
      yield NetworkFailure(
        exception: ServerException(
          message: 'Open-Meteo returned ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      yield NetworkFailure(
        exception: ServerException(
          message: 'Failed to fetch climate data: ${e.message}',
          statusCode: e.response?.statusCode,
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      yield NetworkFailure(
        exception: Exception('Failed to fetch climate data: $e'),
      );
    }
  }

  Stream<NetworkState<Map<String, dynamic>>> fetchHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    try {
      final response = await _getWithRetry(ApiEndpoints.openMeteoForecast, {
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
        yield NetworkSuccess(response.data as Map<String, dynamic>);
        return;
      }
      yield NetworkFailure(
        exception: ServerException(
          message: 'Open-Meteo returned ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      yield NetworkFailure(
        exception: ServerException(
          message: 'Failed to fetch historical data: ${e.message}',
          statusCode: e.response?.statusCode,
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      yield NetworkFailure(
        exception: Exception('Failed to fetch historical data: $e'),
      );
    }
  }

  Stream<NetworkState<Map<String, dynamic>>> fetchArchiveClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    try {
      final response = await _getWithRetry(
        ApiEndpoints.openMeteoArchive,
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
        timeout: const Duration(seconds: 60),
      );
      if (response.statusCode == 200) {
        yield NetworkSuccess(response.data as Map<String, dynamic>);
        return;
      }
      yield NetworkFailure(
        exception: ServerException(
          message: 'Open-Meteo archive returned ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      yield NetworkFailure(
        exception: ServerException(
          message: 'Failed to fetch archive data: ${e.message}',
          statusCode: e.response?.statusCode,
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      yield NetworkFailure(
        exception: Exception('Failed to fetch archive data: $e'),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
