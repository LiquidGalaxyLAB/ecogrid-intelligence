import '../../core/resources/data_state.dart';
import '../model/plant_context_payload.dart';

abstract class AIRepository {
  Stream<DataState<String>> generatePlantInsight({
    required PlantContextPayload context,
    bool isUserInitiated = false,
  });
  Stream<DataState<String>> generateRegionalInsight({
    required String regionName,
    required String riskFilterName,
    required int totalPlants,
    required Map<String, int> riskBreakdown,
    required String dominantRiskDimension,
    required String commonHighRiskType,
    required List<String> top3Plants,
  });
  Stream<DataState<String>> generateScenarioAnalysis({
    required PlantContextPayload context,
    required double projectedCvs,
    required String scenarioType,
  });
  Stream<DataState<String>> generateTrendInsight({
    required PlantContextPayload context,
  });
  String startPlantChat({required PlantContextPayload context});
  Stream<DataState<String>> sendChatMessage({
    required String sessionId,
    required String message,
  });
}
