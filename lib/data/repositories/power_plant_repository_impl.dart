import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';
import 'package:ecogrid_intelligence/data/datasources/local/power_plant_local_ds.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';
import 'package:ecogrid_intelligence/domain/repositories/power_plant_repository.dart';

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
