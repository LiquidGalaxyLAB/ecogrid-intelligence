import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/power_plant.dart';
import '../../../repository/power_plant_repository.dart';

class SearchPlantsUsecase implements UseCase<DataState<List<PowerPlant>>, String> {
  final PowerPlantRepository _repository;

  SearchPlantsUsecase(this._repository);

  @override
  Future<DataState<List<PowerPlant>>> call({String? params}) {
    return _repository.searchPlants(params!);
  }
}
