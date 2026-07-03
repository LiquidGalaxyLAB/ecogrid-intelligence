import '../../core/resources/data_state.dart';
import '../../core/enums/risk_level.dart';
import '../model/cvs_result.dart';
import '../model/power_plant.dart';
import '../model/climate_data.dart';

abstract class CvsRepository {
  Stream<DataState<CvsComputationResult>> getCvsForPlant(PowerPlant plant);
  CVSResult computeInstantCvs(PowerPlant plant);
  CVSResult? getCachedCvs(PowerPlant plant);
  Future<void> preComputeAllScores(List<PowerPlant> plants);
  List<PowerPlant> getPlantsByRiskLevel(
    List<PowerPlant> plants,
    RiskLevel level, {
    int page = 1,
    int pageSize = 15,
  });
  int countPlantsByRiskLevel(List<PowerPlant> plants, RiskLevel level);
  CVSResult getUnifiedScore(PowerPlant plant);
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
