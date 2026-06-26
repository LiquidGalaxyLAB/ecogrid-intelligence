import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/power_plant.dart';
import '../../../repository/power_plant_repository.dart';

class GetAllPlantsUsecase implements UseCase<DataState<List<PowerPlant>>, void> {
  final PowerPlantRepository _repository;

  GetAllPlantsUsecase(this._repository);

  @override
  Future<DataState<List<PowerPlant>>> call({void params}) {
    return _repository.getAllPlants();
  }
}
