import '../../../model/power_plant.dart';
import '../../../model/cvs_result.dart';
import '../../../repository/cvs_repository.dart';

class GetCachedCvsUsecase {
  final CvsRepository repository;
  GetCachedCvsUsecase(this.repository);
  CVSResult? call(PowerPlant plant) {
    return repository.getCachedCvs(plant);
  }
}
