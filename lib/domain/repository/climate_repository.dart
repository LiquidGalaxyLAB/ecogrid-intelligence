import '../../core/resources/data_state.dart';
import '../model/climate_data.dart';

/// Repository interface for climate data operations.
abstract class ClimateRepository {
  /// Get current climate data for a location.
  Future<DataState<ClimateData>> getCurrentClimate(
    double lat,
    double lon,
  );

  /// Get historical climate data for a location over a date range.
  Future<DataState<List<ClimateData>>> getHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get forecast climate data for a location.
  Future<DataState<List<ClimateData>>> getForecastClimate(
    double lat,
    double lon,
  );

  /// Get long-term multi-year trend data for a location.
  Future<DataState<List<ClimateData>>> getMultiYearTrend(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  });
}
