import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';

/// Repository interface for power plant data operations.
abstract class PowerPlantRepository {
  /// Load all power plants from the dataset.
  Future<Either<Failure, List<PowerPlant>>> getAllPlants();

  /// Get plants within a specific region's bounding box.
  Future<Either<Failure, List<PowerPlant>>> getPlantsByRegion(Region region);

  /// Search plants by name, country, or type.
  Future<Either<Failure, List<PowerPlant>>> searchPlants(String query);

  /// Get a single plant by its ID.
  Future<Either<Failure, PowerPlant>> getPlantById(String id);
}
