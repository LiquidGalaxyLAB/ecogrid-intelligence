import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/region.dart';
import '../../../repository/power_plant_repository.dart';

class SearchRegionsUsecase implements UseCase<DataState<List<Region>>, String> {
  final PowerPlantRepository _repository;
  SearchRegionsUsecase(this._repository);
  @override
  Stream<DataState<List<Region>>> call({String? params}) {
    return _repository.searchRegions(params!);
  }
}
