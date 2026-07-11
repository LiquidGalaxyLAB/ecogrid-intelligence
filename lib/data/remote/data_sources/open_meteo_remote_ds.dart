import 'package:dio/dio.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/resources/network_state.dart';
import '../api_services/open_meteo_api_service.dart';

class OpenMeteoRemoteDataSource {
  final OpenMeteoApiService _apiService;
  OpenMeteoRemoteDataSource({required OpenMeteoApiService apiService})
    : _apiService = apiService;

  Stream<NetworkState<Map<String, dynamic>>> fetchCurrentClimate(
    double lat,
    double lon,
  ) => _fetchForecast({
    'latitude': lat,
    'longitude': lon,
    'current':
        'temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code',
    'daily':
        'temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
    'timezone': 'auto',
    'forecast_days': 7,
  });

  Stream<NetworkState<Map<String, dynamic>>> fetchHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) => _fetchForecast({
    'latitude': lat,
    'longitude': lon,
    'start_date': _formatDate(startDate),
    'end_date': _formatDate(endDate),
    'daily':
        'temperature_2m_mean,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
    'timezone': 'auto',
  });

  Stream<NetworkState<Map<String, dynamic>>> fetchArchiveClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    try {
      yield NetworkSuccess(
        await _apiService.getArchive({
          'latitude': lat,
          'longitude': lon,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
          'daily':
              'temperature_2m_mean,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
          'timezone': 'auto',
        }),
      );
    } on DioException catch (error) {
      yield NetworkFailure(
        exception: ServerException(
          message: 'Failed to fetch archive data: ${error.message}',
          statusCode: error.response?.statusCode,
        ),
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      yield NetworkFailure(
        exception: Exception('Failed to fetch archive data: $error'),
      );
    }
  }

  Stream<NetworkState<Map<String, dynamic>>> _fetchForecast(
    Map<String, dynamic> query,
  ) async* {
    yield const NetworkIdle();
    yield const NetworkLoading();
    try {
      yield NetworkSuccess(await _apiService.getForecast(query));
    } on DioException catch (error) {
      yield NetworkFailure(
        exception: ServerException(
          message: 'Failed to fetch climate data: ${error.message}',
          statusCode: error.response?.statusCode,
        ),
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      yield NetworkFailure(
        exception: Exception('Failed to fetch climate data: $error'),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
