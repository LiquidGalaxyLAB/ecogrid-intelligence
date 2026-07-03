import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/power_plant.dart';
import '../../../model/region.dart';
import '../../../repository/power_plant_repository.dart';

class GetPlantsByRegionUsecase
    implements UseCase<DataState<List<PowerPlant>>, Region> {
  final PowerPlantRepository _repository;
  GetPlantsByRegionUsecase(this._repository);
  @override
  Stream<DataState<List<PowerPlant>>> call({Region? params}) {
    return _repository.getPlantsByRegion(params!);
  }
}
