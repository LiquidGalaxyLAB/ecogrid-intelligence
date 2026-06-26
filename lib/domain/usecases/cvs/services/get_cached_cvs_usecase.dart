import '../../../model/power_plant.dart';
import '../../../model/cvs_result.dart';
import '../../../repository/cvs_repository.dart';

/// Synchronous use case: retrieves cached CVS result for a plant.
/// Returns null if no cached score exists yet.
class GetCachedCvsUsecase {
  final CvsRepository repository;

  GetCachedCvsUsecase(this.repository);

  CVSResult? call(PowerPlant plant) {
    return repository.getCachedCvs(plant);
  }
}
