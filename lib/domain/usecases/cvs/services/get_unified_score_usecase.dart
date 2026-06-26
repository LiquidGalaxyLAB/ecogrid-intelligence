import '../../../model/power_plant.dart';
import '../../../model/cvs_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../repository/cvs_repository.dart';

class GetUnifiedScoreUsecase implements SyncUseCase<CVSResult, PowerPlant> {
  final CvsRepository repository;

  GetUnifiedScoreUsecase(this.repository);

  @override
  CVSResult call(PowerPlant params) {
    return repository.getUnifiedScore(params);
  }
}
