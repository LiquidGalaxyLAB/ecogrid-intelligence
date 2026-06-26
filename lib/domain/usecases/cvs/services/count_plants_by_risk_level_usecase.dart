import '../../../model/power_plant.dart';
import '../../../../core/enums/risk_level.dart';
import '../../../repository/cvs_repository.dart';

/// Synchronous use case: counts plants at a given risk level from an
/// in-memory list using pre-computed CVS scores.
class CountPlantsByRiskLevelUsecase {
  final CvsRepository repository;

  CountPlantsByRiskLevelUsecase(this.repository);

  int call(List<PowerPlant> plants, RiskLevel level) {
    return repository.countPlantsByRiskLevel(plants, level);
  }
}
