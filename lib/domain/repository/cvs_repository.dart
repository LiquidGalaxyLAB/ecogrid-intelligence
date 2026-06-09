import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';
import 'package:ecogrid_intelligence/domain/model/cvs_result.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/climate_data.dart';

abstract class CvsRepository {
  /// Computes (or retrieves from cache) the CVS for a specific plant.
  /// Also returns the raw current weather data if it was fetched.
  Future<Either<Failure, CvsComputationResult>> getCvsForPlant(
    PowerPlant plant,
  );

  /// Instantly computes a CVS score from plant coordinates alone (no API).
  /// Used for immediate UI rendering before API data arrives.
  CVSResult computeInstantCvs(PowerPlant plant);

  /// Returns the cached CVS result for a plant if it exists, otherwise null.
  CVSResult? getCachedCvs(PowerPlant plant);

  /// Pre-compute instant CVS scores for all plants (runs on background isolate).
  Future<void> preComputeAllScores(List<PowerPlant> plants);

  /// Filter plants by risk level, sorted by score descending, paginated.
  List<PowerPlant> getPlantsByRiskLevel(
    List<PowerPlant> plants,
    RiskLevel level, {
    int page = 1,
    int pageSize = 15,
  });

  /// Count how many plants match a given risk level.
  int countPlantsByRiskLevel(List<PowerPlant> plants, RiskLevel level);

  /// Get the unified CVS score for a plant (Single Source of Truth).
  CVSResult getUnifiedScore(PowerPlant plant);

  /// Clears the memory cache.
  void clearCache();
}

class CvsComputationResult {
  final CVSResult cvsResult;
  final ClimateData currentClimate;
  final List<ClimateData> historicalData;

  CvsComputationResult({
    required this.cvsResult,
    required this.currentClimate,
    required this.historicalData,
  });
}
