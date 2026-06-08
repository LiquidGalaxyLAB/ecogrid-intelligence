import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';

/// Repository interface for power plant data operations.
abstract class PowerPlantRepository {
  /// Load all power plants from the dataset.
  Future<Either<Failure, List<PowerPlant>>> getAllPlants();

  /// Get plants within a specific region's bounding box.
  Future<Either<Failure, List<PowerPlant>>> getPlantsByRegion(Region region);

  /// Search plants by name, country, or type.
  Future<Either<Failure, List<PowerPlant>>> searchPlants(String query);

  /// Search for regions matching a query.
  Future<Either<Failure, List<Region>>> searchRegions(String query);

  /// Get a single plant by its ID.
  Future<Either<Failure, PowerPlant>> getPlantById(String id);
}
