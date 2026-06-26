import '../../../../core/resources/data_state.dart';
import '../../../repository/power_plant_repository.dart';
import '../../../model/power_plant.dart';

class InitPlantBlocUseCase {
  final PowerPlantRepository _repository;

  InitPlantBlocUseCase(this._repository);

  Future<DataState<List<PowerPlant>>> call() {
    return _repository.getAllPlants();
  }
}

