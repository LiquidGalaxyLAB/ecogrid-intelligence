import 'package:dio/dio.dart';
import 'package:ecogrid_intelligence/config/app_config.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';

/// Remote data source for Open-Meteo API.
class OpenMeteoRemoteDataSource {
  final Dio dio;

  OpenMeteoRemoteDataSource({required this.dio});

  /// Fetch current weather + anomaly data for a location.
  Future<Map<String, dynamic>> fetchCurrentClimate(
      double lat, double lon) async {
    try {
      final response = await dio.get(
        AppConfig.openMeteoForecast,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,relative_humidity_2m,precipitation,'
              'wind_speed_10m,weather_code',
          'daily': 'temperature_2m_max,temperature_2m_min,'
              'precipitation_sum,wind_speed_10m_max',
          'timezone': 'auto',
          'forecast_days': 7,
        },
      );

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

  /// Fetch historical climate data for a date range.
  Future<Map<String, dynamic>> fetchHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await dio.get(
        AppConfig.openMeteoArchive,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
          'daily': 'temperature_2m_mean,temperature_2m_max,temperature_2m_min,'
              'precipitation_sum,wind_speed_10m_max',
          'timezone': 'auto',
        },
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
        message: 'Failed to fetch historical data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
