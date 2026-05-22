import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';

/// Repository interface for AI (Gemini) operations.
abstract class AIRepository {
  /// Generate a climate insight for a specific power plant.
  Future<Either<Failure, String>> generatePlantInsight({
    required String plantName,
    required String plantType,
    required double cvsScore,
    required double tempStress,
    required double waterStress,
    required double windStress,
    required String country,
  });

  /// Generate a regional climate summary.
  Future<Either<Failure, String>> generateRegionalInsight({
    required String regionName,
    required int totalPlants,
    required int highRiskPlants,
    required Map<String, int> plantTypeDistribution,
  });

  /// Generate scenario analysis text.
  Future<Either<Failure, String>> generateScenarioAnalysis({
    required String plantName,
    required String plantType,
    required double currentCvs,
    required double projectedCvs,
    required String scenarioType,
  });
}
