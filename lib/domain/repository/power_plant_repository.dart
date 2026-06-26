import '../../core/resources/data_state.dart';
import '../model/power_plant.dart';
import '../model/region.dart';

/// Repository interface for power plant data operations.
abstract class PowerPlantRepository {
  /// Load all power plants from the dataset.
  Future<DataState<List<PowerPlant>>> getAllPlants();

  /// Get plants within a specific region's bounding box.
  Future<DataState<List<PowerPlant>>> getPlantsByRegion(Region region);

  /// Search plants by name, country, or type.
  Future<DataState<List<PowerPlant>>> searchPlants(String query);

  /// Search for regions matching a query.
  Future<DataState<List<Region>>> searchRegions(String query);

  /// Get a single plant by its ID.
  Future<DataState<PowerPlant>> getPlantById(String id);
}
