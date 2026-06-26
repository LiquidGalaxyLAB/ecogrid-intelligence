import '../../../model/power_plant.dart';
import '../../../../core/enums/risk_level.dart';
import '../../../repository/cvs_repository.dart';

/// Synchronous use case: returns paginated plants at a given risk level
/// from an in-memory list using pre-computed CVS scores.
class GetPlantsByRiskLevelUsecase {
  final CvsRepository repository;

  GetPlantsByRiskLevelUsecase(this.repository);

  List<PowerPlant> call(
    List<PowerPlant> plants,
    RiskLevel level, {
    int page = 1,
    int pageSize = 15,
  }) {
    return repository.getPlantsByRiskLevel(plants, level, page: page, pageSize: pageSize);
  }
}
