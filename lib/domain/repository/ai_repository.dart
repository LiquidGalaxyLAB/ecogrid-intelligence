import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/domain/model/plant_context_payload.dart';

/// Repository interface for AI operations.
///
/// This interface is provider-agnostic — it knows nothing about Groq, Gemini,
/// or any specific AI service. The implementation handles provider details.
abstract class AIRepository {
  /// Generate a climate insight for a specific power plant.
  /// Uses the full PlantContextPayload for rich, contextual responses.
  Future<Either<Failure, String>> generatePlantInsight({
    required PlantContextPayload context,
    bool isUserInitiated = false,
  });

  /// Generate a regional climate summary.
  Future<Either<Failure, String>> generateRegionalInsight({
    required String regionName,
    required String riskFilterName,
    required int totalPlants,
    required Map<String, int> riskBreakdown,
    required String dominantRiskDimension,
    required String commonHighRiskType,
    required List<String> top3Plants,
  });

  /// Generate scenario analysis text using full plant context.
  Future<Either<Failure, String>> generateScenarioAnalysis({
    required PlantContextPayload context,
    required double projectedCvs,
    required String scenarioType,
  });

  /// Generate an explanation of the historical climate trend for a plant.
  Future<Either<Failure, String>> generateTrendInsight({
    required PlantContextPayload context,
  });

  /// Start a conversational chat session about a specific plant.
  /// Returns a session ID that can be used with [sendChatMessage].
  String startPlantChat({required PlantContextPayload context});

  /// Send a message within an existing chat session.
  Future<Either<Failure, String>> sendChatMessage({
    required String sessionId,
    required String message,
  });
}
