import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/domain/entities/climate_data.dart';

/// Repository interface for climate data operations.
abstract class ClimateRepository {
  /// Get current climate data for a location.
  Future<Either<Failure, ClimateData>> getCurrentClimate(
      double lat, double lon);

  /// Get historical climate data for a location over a date range.
  Future<Either<Failure, List<ClimateData>>> getHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get forecast climate data for a location.
  Future<Either<Failure, List<ClimateData>>> getForecastClimate(
      double lat, double lon);
}
