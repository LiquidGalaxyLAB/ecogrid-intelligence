import '../../core/exception/invalid_response_exception.dart';
import '../../core/exception/unhandled_exception.dart';
import '../../core/resources/data_state.dart';
import '../local/data_sources/power_plant_local_ds.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/region.dart';
import '../../domain/repository/power_plant_repository.dart';

class PowerPlantRepositoryImpl implements PowerPlantRepository {
  final PowerPlantLocalDataSource _localDataSource;
  PowerPlantRepositoryImpl({required this._localDataSource});
  @override
  Stream<DataState<List<PowerPlant>>> getAllPlants() async* {
    yield const DataLoading();
    try {
      final plants = await _localDataSource.getAllPlants();
      if (plants.isEmpty) {
        yield const DataEmpty();
      } else {
        yield DataSuccess(plants);
      }
    } on ParseException catch (e) {
      yield DataFailure(
        InvalidResponseException(message: e.message, response: null),
      );
    } catch (e) {
      yield DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Stream<DataState<List<PowerPlant>>> getPlantsByRegion(Region region) async* {
    yield const DataLoading();
    try {
      final plants = await _localDataSource.getPlantsByRegion(region);
      if (plants.isEmpty) {
        yield const DataEmpty();
      } else {
        yield DataSuccess(plants);
      }
    } catch (e) {
      yield DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Stream<DataState<List<PowerPlant>>> searchPlants(String query) async* {
    yield const DataLoading();
    try {
      final plants = await _localDataSource.searchPlants(query);
      yield DataSuccess(plants);
    } catch (e) {
      yield DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Stream<DataState<List<Region>>> searchRegions(String query) async* {
    yield const DataLoading();
    try {
      final regions = await _localDataSource.searchRegions(query);
      yield DataSuccess(regions);
    } catch (e) {
      yield DataFailure(UnhandledException(message: e.toString()));
    }
  }

  @override
  Stream<DataState<PowerPlant>> getPlantById(String id) async* {
    yield const DataLoading();
    try {
      final plant = await _localDataSource.getPlantById(id);
      if (plant == null) {
        yield DataFailure(
          InvalidResponseException(
            message: 'Power plant not found',
            response: id,
          ),
        );
      } else {
        yield DataSuccess(plant);
      }
    } catch (e) {
      yield DataFailure(UnhandledException(message: e.toString()));
    }
  }
}
