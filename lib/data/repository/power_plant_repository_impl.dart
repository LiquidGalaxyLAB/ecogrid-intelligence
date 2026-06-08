import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/core/exception/exceptions.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/power_plant_local_ds.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';
import 'package:ecogrid_intelligence/domain/repository/power_plant_repository.dart';

class PowerPlantRepositoryImpl implements PowerPlantRepository {
  final PowerPlantLocalDataSource localDataSource;

  PowerPlantRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<PowerPlant>>> getAllPlants() async {
    try {
      final plants = await localDataSource.getAllPlants();
      return Right(plants);
    } on ParseException catch (e) {
      return Left(ParseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PowerPlant>>> getPlantsByRegion(
      Region region) async {
    try {
      final plants = await localDataSource.getPlantsByRegion(region);
      return Right(plants);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PowerPlant>>> searchPlants(String query) async {
    try {
      final plants = await localDataSource.searchPlants(query);
      return Right(plants);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Region>>> searchRegions(String query) async {
    try {
      final regions = await localDataSource.searchRegions(query);
      return Right(regions);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PowerPlant>> getPlantById(String id) async {
    try {
      final plant = await localDataSource.getPlantById(id);
      if (plant == null) {
        return const Left(
            ParseFailure(message: 'Power plant not found'));
      }
      return Right(plant);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
