import '../../../model/power_plant.dart';
import '../../../repository/cvs_repository.dart';

class PreComputeAllScoresUsecase {
  final CvsRepository repository;
  PreComputeAllScoresUsecase(this.repository);
  Future<void> call(List<PowerPlant> plants) {
    return repository.preComputeAllScores(plants);
  }
}
