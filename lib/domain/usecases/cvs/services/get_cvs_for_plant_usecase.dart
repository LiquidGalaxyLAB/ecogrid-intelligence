import '../../../../core/resources/data_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../model/power_plant.dart';
import '../../../repository/cvs_repository.dart';

class GetCvsForPlantUsecase
    implements UseCase<DataState<CvsComputationResult>, PowerPlant> {
  final CvsRepository _repository;

  GetCvsForPlantUsecase(this._repository);

  @override
  Future<DataState<CvsComputationResult>> call({PowerPlant? params}) {
    return _repository.getCvsForPlant(params!);
  }
}
