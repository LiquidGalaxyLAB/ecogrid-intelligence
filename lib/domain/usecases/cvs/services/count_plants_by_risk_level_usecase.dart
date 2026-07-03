import '../../../model/power_plant.dart';
import '../../../../core/enums/risk_level.dart';
import '../../../repository/cvs_repository.dart';

class CountPlantsByRiskLevelUsecase {
  final CvsRepository repository;
  CountPlantsByRiskLevelUsecase(this.repository);
  int call(List<PowerPlant> plants, RiskLevel level) {
    return repository.countPlantsByRiskLevel(plants, level);
  }
}
