import '../../core/exception/unhandled_exception.dart';
import '../../core/resources/data_state.dart';
import '../../core/resources/network_state.dart';
import '../local/data_sources/climate_cache_ds.dart';
import '../remote/data_sources/open_meteo_remote_ds.dart';
import '../../domain/model/climate_data.dart';
import '../../domain/repository/climate_repository.dart';

class ClimateRepositoryImpl implements ClimateRepository {
  final OpenMeteoRemoteDataSource _remoteDataSource;
  final ClimateCacheDataSource _cacheDataSource;
  ClimateRepositoryImpl({
    required this._remoteDataSource,
    required this._cacheDataSource,
  });
  @override
  Stream<DataState<ClimateData>> getCurrentClimate(
    double lat,
    double lon,
  ) async* {
    final cached = await _cacheDataSource.getCachedClimate(lat, lon);
    if (cached != null && cached.isFresh) {
      yield DataSuccess(_mapToClimateData(cached.data, lat, lon));
    }
    final stream = _remoteDataSource.fetchCurrentClimate(lat, lon);
    await for (final networkState in stream) {
      if (networkState is NetworkIdle || networkState is NetworkLoading) {
        if (cached == null) {
          yield const DataLoading();
        }
      } else if (networkState is NetworkSuccess<Map<String, dynamic>>) {
        final response = networkState.data;
        await _cacheDataSource.cacheClimateData(lat, lon, response);
        yield DataSuccess(_mapApiResponseToClimateData(response, lat, lon));
      } else if (networkState is NetworkFailure) {
        if (cached == null) {
          yield DataFailure(
            (networkState as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown network error'),
          );
        }
      }
    }
  }

  @override
  Stream<DataState<List<ClimateData>>> getHistoricalClimate(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final cached = await _cacheDataSource.getCachedClimate(
      lat,
      lon,
      prefix: 'historical',
    );
    if (cached != null && cached.isFresh) {
      yield DataSuccess(_parseHistoricalData(cached.data, lat, lon));
    }
    final stream = _remoteDataSource.fetchHistoricalClimate(
      lat,
      lon,
      startDate: startDate,
      endDate: endDate,
    );
    await for (final networkState in stream) {
      if (networkState is NetworkIdle || networkState is NetworkLoading) {
        if (cached == null) {
          yield const DataLoading();
        }
      } else if (networkState is NetworkSuccess<Map<String, dynamic>>) {
        final response = networkState.data;
        await _cacheDataSource.cacheClimateData(
          lat,
          lon,
          response,
          prefix: 'historical',
        );
        yield DataSuccess(_parseHistoricalData(response, lat, lon));
      } else if (networkState is NetworkFailure) {
        if (cached == null) {
          yield DataFailure(
            (networkState as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown network error'),
          );
        }
      }
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
  Stream<DataState<List<ClimateData>>> getMultiYearTrend(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final cached = await _cacheDataSource.getCachedClimate(
      lat,
      lon,
      prefix: 'trend_${startDate.year}',
    );
    if (cached != null && cached.isFresh) {
      yield DataSuccess(_parseMultiYearHistoricalData(cached.data, lat, lon));
    }
    final stream = _remoteDataSource.fetchArchiveClimate(
      lat,
      lon,
      startDate: startDate,
      endDate: endDate,
    );
    await for (final networkState in stream) {
      if (networkState is NetworkIdle || networkState is NetworkLoading) {
        if (cached == null) {
          yield const DataLoading();
        }
      } else if (networkState is NetworkSuccess<Map<String, dynamic>>) {
        final response = networkState.data;
        await _cacheDataSource.cacheClimateData(
          lat,
          lon,
          response,
          prefix: 'trend_${startDate.year}',
        );
        yield DataSuccess(_parseMultiYearHistoricalData(response, lat, lon));
      } else if (networkState is NetworkFailure) {
        if (cached == null) {
          yield DataFailure(
            (networkState as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown network error'),
          );
        }
      }
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
      double maxWind = 0;
      double sumWind = 0;
      int countWind = 0;
      for (final d in days) {
        if (d['t']! != -999.0) {
          sumMaxTemp += d['t']!;
          countMaxTemp++;
        }
        sumPrecip += d['p']!;
        if (d['w']! != -999.0) {
          sumWind += d['w']!;
          countWind++;
          if (d['w']! > maxWind) maxWind = d['w']!;
        }
      }
      final meanMaxTemp = countMaxTemp > 0 ? sumMaxTemp / countMaxTemp : null;
      final meanMaxWind = countWind > 0 ? sumWind / countWind : null;
      results.add(
        ClimateData(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime(year, 1, 1),
          temperature: meanMaxTemp,
          precipitation: sumPrecip,
          windSpeed: meanMaxWind,
        ),
      );
    }
    return results;
  }

  @override
  Stream<DataState<List<ClimateData>>> getForecastClimate(
    double lat,
    double lon,
  ) async* {
    final stream = _remoteDataSource.fetchCurrentClimate(lat, lon);
    await for (final networkState in stream) {
      if (networkState is NetworkIdle || networkState is NetworkLoading) {
        yield const DataLoading();
      } else if (networkState is NetworkSuccess<Map<String, dynamic>>) {
        final response = networkState.data;
        final rawDaily = response['daily'];
        final dailyData = rawDaily != null
            ? Map<String, dynamic>.from(rawDaily as Map)
            : null;
        if (dailyData == null) {
          yield const DataSuccess([]);
          continue;
        }
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
        yield DataSuccess(results);
      } else if (networkState is NetworkFailure) {
        yield DataFailure(
          (networkState as NetworkFailure).exception ??
              UnhandledException(message: 'Unknown network error'),
        );
      }
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
      tempAnomaly: 0.0,
      waterAnomaly: 0.0,
      windAnomaly: 0.0,
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
