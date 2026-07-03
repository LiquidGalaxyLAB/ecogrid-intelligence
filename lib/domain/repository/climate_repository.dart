import '../../core/resources/data_state.dart';
import '../model/climate_data.dart';

abstract class ClimateRepository {
  Stream<DataState<ClimateData>> getCurrentClimate(double lat, double lon);
  Stream<DataState<List<ClimateData>>> getHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  });
  Stream<DataState<List<ClimateData>>> getForecastClimate(
    double lat,
    double lon,
  );
  Stream<DataState<List<ClimateData>>> getMultiYearTrend(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  });
}
