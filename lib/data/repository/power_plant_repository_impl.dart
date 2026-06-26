import '../../core/exception/invalid_response_exception.dart';
import '../../core/exception/unhandled_exception.dart';
import '../../core/resources/data_state.dart';

import '../data_sources/local/power_plant_local_ds.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/region.dart';
import '../../domain/repository/power_plant_repository.dart';

class PowerPlantRepositoryImpl implements PowerPlantRepository {
  final PowerPlantLocalDataSource _localDataSource;

  PowerPlantRepositoryImpl({required this._localDataSource});

  @override
  Future<DataState<List<PowerPlant>>> getAllPlants() async {
    try {
      final plants = await _localDataSource.getAllPlants();
      return DataSuccess(plants);
    } on ParseException catch (e) {
      return DataFailure(InvalidResponseException(
        message: e.message,
        response: null,
      ));
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Future<DataState<List<PowerPlant>>> getPlantsByRegion(Region region) async {
    try {
      final plants = await _localDataSource.getPlantsByRegion(region);
      return DataSuccess(plants);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Future<DataState<List<PowerPlant>>> searchPlants(String query) async {
    try {
      final plants = await _localDataSource.searchPlants(query);
      return DataSuccess(plants);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Future<DataState<List<Region>>> searchRegions(String query) async {
    try {
      final regions = await _localDataSource.searchRegions(query);
      return DataSuccess(regions);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Future<DataState<PowerPlant>> getPlantById(String id) async {
    try {
      final plant = await _localDataSource.getPlantById(id);
      if (plant == null) {
        return DataFailure(InvalidResponseException(
          message: 'Power plant not found',
          response: id,
        ));
      }
      return DataSuccess(plant);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }
}
