import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/core/exception/exceptions.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/climate_cache_ds.dart';
import 'package:ecogrid_intelligence/data/data_sources/remote/open_meteo_remote_ds.dart';
import 'package:ecogrid_intelligence/domain/model/climate_data.dart';
import 'package:ecogrid_intelligence/domain/repository/climate_repository.dart';

class ClimateRepositoryImpl implements ClimateRepository {
  final OpenMeteoRemoteDataSource remoteDataSource;
  final ClimateCacheDataSource cacheDataSource;

  ClimateRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
  });

  @override
  Future<Either<Failure, ClimateData>> getCurrentClimate(
    double lat,
    double lon,
  ) async {
    // Check cache first (stale-while-revalidate)
    final cached = await cacheDataSource.getCachedClimate(lat, lon);
    if (cached != null && cached.isFresh) {
      return Right(_mapToClimateData(cached.data, lat, lon));
    }

    try {
      // Fetch fresh data
      final response = await remoteDataSource.fetchCurrentClimate(lat, lon);
      await cacheDataSource.cacheClimateData(lat, lon, response);

      return Right(_mapApiResponseToClimateData(response, lat, lon));
    } on ServerException catch (e) {
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
    // Check local cache first (aggressive geo-spatial caching)
    final cached = await cacheDataSource.getCachedClimate(
      lat,
      lon,
      prefix: 'historical',
    );
    if (cached != null && cached.isFresh) {
      return Right(_parseHistoricalData(cached.data, lat, lon));
    }

    try {
      final response = await remoteDataSource.fetchHistoricalClimate(
        lat,
        lon,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the raw JSON response
      await cacheDataSource.cacheClimateData(
        lat,
        lon,
        response,
        prefix: 'historical',
      );

      return Right(_parseHistoricalData(response, lat, lon));
    } on ServerException catch (e) {
      if (cached != null) {
        return Right(_parseHistoricalData(cached.data, lat, lon));
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      if (cached != null) {
        return Right(_parseHistoricalData(cached.data, lat, lon));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  List<ClimateData> _parseHistoricalData(
    Map<String, dynamic> response,
    double lat,
    double lon,
  ) {
    final rawDaily = response['daily'];
    final dailyData = rawDaily != null
        ? Map<String, dynamic>.from(rawDaily as Map)
        : null;
    if (dailyData == null) return [];

    final dates = (dailyData['time'] as List?)?.cast<String>() ?? [];
    final temps =
        (dailyData['temperature_2m_mean'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];
    final precip =
        (dailyData['precipitation_sum'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];
    final wind =
        (dailyData['wind_speed_10m_max'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];

    final results = <ClimateData>[];
    for (int i = 0; i < dates.length; i++) {
      results.add(
        ClimateData(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.parse(dates[i]),
          temperature: i < temps.length ? temps[i] : null,
          precipitation: i < precip.length ? precip[i] : null,
          windSpeed: i < wind.length ? wind[i] : null,
        ),
      );
    }
    return results;
  }

  @override
  Future<Either<Failure, List<ClimateData>>> getMultiYearTrend(
    double lat,
    double lon,
  ) async {
    // Check local cache
    final cached = await cacheDataSource.getCachedClimate(
      lat,
      lon,
      prefix: 'trend',
    );
    if (cached != null && cached.isFresh) {
      return Right(_parseMultiYearHistoricalData(cached.data, lat, lon));
    }

    try {
      final response = await remoteDataSource.fetchArchiveClimate(
        lat,
        lon,
        startDate: DateTime(DateTime.now().year - 10, 1, 1),
        endDate: DateTime(
          DateTime.now().year,
          1,
          1,
        ).subtract(const Duration(days: 1)),
      );

      await cacheDataSource.cacheClimateData(
        lat,
        lon,
        response,
        prefix: 'trend',
      );

      return Right(_parseMultiYearHistoricalData(response, lat, lon));
    } on ServerException catch (e) {
      if (cached != null) {
        return Right(_parseMultiYearHistoricalData(cached.data, lat, lon));
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      if (cached != null) {
        return Right(_parseMultiYearHistoricalData(cached.data, lat, lon));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  List<ClimateData> _parseMultiYearHistoricalData(
    Map<String, dynamic> response,
    double lat,
    double lon,
  ) {
    final rawDaily = response['daily'];
    final dailyData = rawDaily != null
        ? Map<String, dynamic>.from(rawDaily as Map)
        : null;
    if (dailyData == null) return [];

    final dates = (dailyData['time'] as List?)?.cast<String>() ?? [];
    final maxTemps =
        (dailyData['temperature_2m_max'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];
    final precip =
        (dailyData['precipitation_sum'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];
    final wind =
        (dailyData['wind_speed_10m_max'] as List?)
            ?.map((e) => (e as num?)?.toDouble())
            .toList() ??
        [];

    final yearData = <int, List<Map<String, double>>>{};
    for (int i = 0; i < dates.length; i++) {
      final date = DateTime.tryParse(dates[i]);
      if (date == null) continue;
      final year = date.year;

      yearData.putIfAbsent(year, () => []);
      yearData[year]!.add({
        't': i < maxTemps.length ? (maxTemps[i] ?? -999.0) : -999.0,
        'p': i < precip.length ? (precip[i] ?? 0.0) : 0.0,
        'w': i < wind.length ? (wind[i] ?? -999.0) : -999.0,
      });
    }

    final results = <ClimateData>[];
    final sortedYears = yearData.keys.toList()..sort();

    for (final year in sortedYears) {
      final days = yearData[year]!;

      double sumMaxTemp = 0;
      int countMaxTemp = 0;

      double sumPrecip = 0;

      double maxWind = 0; // or mean max wind
      double sumWind = 0;
      int countWind = 0;

      for (final d in days) {
        if (d['t']! != -999.0) {
          sumMaxTemp += d['t']!;
          countMaxTemp++;
        }
        sumPrecip += d['p']!; // annual sum
        if (d['w']! != -999.0) {
          sumWind += d['w']!;
          countWind++;
          if (d['w']! > maxWind) maxWind = d['w']!;
        }
      }

      final meanMaxTemp = countMaxTemp > 0 ? sumMaxTemp / countMaxTemp : null;
      // We will use mean of max wind as it's more stable for trends than absolute single-day max
      final meanMaxWind = countWind > 0 ? sumWind / countWind : null;

      results.add(
        ClimateData(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime(year, 1, 1),
          temperature: meanMaxTemp,
          precipitation: sumPrecip, // Annual sum
          windSpeed: meanMaxWind,
        ),
      );
    }
    return results;
  }

  @override
  Future<Either<Failure, List<ClimateData>>> getForecastClimate(
    double lat,
    double lon,
  ) async {
    try {
      final response = await remoteDataSource.fetchCurrentClimate(lat, lon);
      final rawDaily = response['daily'];
      final dailyData = rawDaily != null
          ? Map<String, dynamic>.from(rawDaily as Map)
          : null;
      if (dailyData == null) return const Right([]);

      final dates = (dailyData['time'] as List?)?.cast<String>() ?? [];
      final maxTemps =
          (dailyData['temperature_2m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final precip =
          (dailyData['precipitation_sum'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];
      final wind =
          (dailyData['wind_speed_10m_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble())
              .toList() ??
          [];

      final results = <ClimateData>[];
      for (int i = 0; i < dates.length; i++) {
        results.add(
          ClimateData(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.parse(dates[i]),
            temperature: i < maxTemps.length ? maxTemps[i] : null,
            precipitation: i < precip.length ? precip[i] : null,
            windSpeed: i < wind.length ? wind[i] : null,
          ),
        );
      }

      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  ClimateData _mapApiResponseToClimateData(
    Map<String, dynamic> response,
    double lat,
    double lon,
  ) {
    final rawCurrent = response['current'];
    final current = rawCurrent != null
        ? Map<String, dynamic>.from(rawCurrent as Map)
        : null;

    final temp = (current?['temperature_2m'] as num?)?.toDouble() ?? 0;
    final precip = (current?['precipitation'] as num?)?.toDouble() ?? 0;
    final wind = (current?['wind_speed_10m'] as num?)?.toDouble() ?? 0;
    final humidity =
        (current?['relative_humidity_2m'] as num?)?.toDouble() ?? 0;

    return ClimateData(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      temperature: temp,
      precipitation: precip,
      windSpeed: wind,
      humidity: humidity,
      tempAnomaly: 0.0, // Calculated later by AnomalyEngine
      waterAnomaly: 0.0, // Calculated later by AnomalyEngine
      windAnomaly: 0.0, // Calculated later by AnomalyEngine
    );
  }

  ClimateData _mapToClimateData(
    Map<String, dynamic> data,
    double lat,
    double lon,
  ) {
    return _mapApiResponseToClimateData(data, lat, lon);
  }
}
