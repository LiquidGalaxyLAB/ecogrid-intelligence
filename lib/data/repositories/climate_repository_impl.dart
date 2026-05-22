import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';
import 'package:ecogrid_intelligence/data/datasources/local/climate_cache_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/open_meteo_remote_ds.dart';
import 'package:ecogrid_intelligence/domain/entities/climate_data.dart';
import 'package:ecogrid_intelligence/domain/repositories/climate_repository.dart';

class ClimateRepositoryImpl implements ClimateRepository {
  final OpenMeteoRemoteDataSource remoteDataSource;
  final ClimateCacheDataSource cacheDataSource;

  ClimateRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
  });

  @override
  Future<Either<Failure, ClimateData>> getCurrentClimate(
      double lat, double lon) async {
    // Check cache first (stale-while-revalidate)
    final cached = cacheDataSource.getCachedClimate(lat, lon);
    if (cached != null && cached.isFresh) {
      return Right(_mapToClimateData(cached.data, lat, lon));
    }

    try {
      // Fetch fresh data
      final response =
          await remoteDataSource.fetchCurrentClimate(lat, lon);
      await cacheDataSource.cacheClimateData(lat, lon, response);

      return Right(_mapApiResponseToClimateData(response, lat, lon));
    } on ServerException catch (e) {
      // If stale data exists, return it
      if (cached != null) {
        return Right(_mapToClimateData(cached.data, lat, lon));
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      if (cached != null) {
        return Right(_mapToClimateData(cached.data, lat, lon));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClimateData>>> getHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await remoteDataSource.fetchHistoricalClimate(
        lat,
        lon,
        startDate: startDate,
        endDate: endDate,
      );

      final dailyData = response['daily'] as Map<String, dynamic>?;
      if (dailyData == null) {
        return const Right([]);
      }

      final dates = (dailyData['time'] as List?)?.cast<String>() ?? [];
      final temps = (dailyData['temperature_2m_mean'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final precip = (dailyData['precipitation_sum'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final wind = (dailyData['wind_speed_10m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];

      final results = <ClimateData>[];
      for (int i = 0; i < dates.length; i++) {
        results.add(ClimateData(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.parse(dates[i]),
          temperature: i < temps.length ? temps[i] : null,
          precipitation: i < precip.length ? precip[i] : null,
          windSpeed: i < wind.length ? wind[i] : null,
        ));
      }

      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClimateData>>> getForecastClimate(
      double lat, double lon) async {
    try {
      final response =
          await remoteDataSource.fetchCurrentClimate(lat, lon);
      final dailyData = response['daily'] as Map<String, dynamic>?;
      if (dailyData == null) return const Right([]);

      final dates = (dailyData['time'] as List?)?.cast<String>() ?? [];
      final maxTemps = (dailyData['temperature_2m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final precip = (dailyData['precipitation_sum'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final wind = (dailyData['wind_speed_10m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];

      final results = <ClimateData>[];
      for (int i = 0; i < dates.length; i++) {
        results.add(ClimateData(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.parse(dates[i]),
          temperature: i < maxTemps.length ? maxTemps[i] : null,
          precipitation: i < precip.length ? precip[i] : null,
          windSpeed: i < wind.length ? wind[i] : null,
        ));
      }

      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  ClimateData _mapApiResponseToClimateData(
      Map<String, dynamic> response, double lat, double lon) {
    final current = response['current'] as Map<String, dynamic>?;

    final temp = (current?['temperature_2m'] as num?)?.toDouble() ?? 0;
    final precip = (current?['precipitation'] as num?)?.toDouble() ?? 0;
    final wind = (current?['wind_speed_10m'] as num?)?.toDouble() ?? 0;
    final humidity =
        (current?['relative_humidity_2m'] as num?)?.toDouble() ?? 0;

    // Normalize anomalies (simplified — in production, compare to 30-year baseline)
    final tempAnomaly = ((temp - 25).abs() / 30).clamp(0.0, 1.0);
    final waterAnomaly = precip > 0
        ? 0.2
        : (humidity < 30 ? 0.8 : (humidity < 50 ? 0.5 : 0.3));
    final windAnomaly = (wind / 100).clamp(0.0, 1.0);

    return ClimateData(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      temperature: temp,
      precipitation: precip,
      windSpeed: wind,
      humidity: humidity,
      tempAnomaly: tempAnomaly,
      waterAnomaly: waterAnomaly,
      windAnomaly: windAnomaly,
    );
  }

  ClimateData _mapToClimateData(
      Map<String, dynamic> data, double lat, double lon) {
    return _mapApiResponseToClimateData(data, lat, lon);
  }
}
