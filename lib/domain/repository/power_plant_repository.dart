import '../../core/resources/data_state.dart';
import '../model/power_plant.dart';
import '../model/region.dart';

abstract class PowerPlantRepository {
  Stream<DataState<List<PowerPlant>>> getAllPlants();
  Stream<DataState<List<PowerPlant>>> getPlantsByRegion(Region region);
  Stream<DataState<List<PowerPlant>>> searchPlants(String query);
  Stream<DataState<List<Region>>> searchRegions(String query);
  Stream<DataState<PowerPlant>> getPlantById(String id);
}
