import 'dart:convert';

// ignore_for_file: prefer_initializing_formals

import '../../../core/constants/cache_constants.dart';
import '../../../core/utils/cache_manager.dart';
import 'app_database.dart';

/// Local cache data source for climate data using Drift + stale-while-revalidate.
///
/// Cache keys, expiration durations, and freshness logic are UNCHANGED from
/// the previous Hive implementation. Only the underlying storage engine changed.
class ClimateCacheDataSource {
  final ClimateDao _dao;

  ClimateCacheDataSource({required ClimateDao dao}) : _dao = dao;

  /// Generate a cache key from coordinates.
  String _cacheKey(double lat, double lon, {String prefix = 'current'}) {
    // Current weather needs higher spatial precision (2 decimal places ~ 1.1km)
    // Historical climate anomalies are broader (1 decimal place ~ 11km)
    final decimals = prefix == 'historical' ? 1 : 2;
    final latKey = lat.toStringAsFixed(decimals);
    final lonKey = lon.toStringAsFixed(decimals);
    return '${prefix}_${latKey}_$lonKey';
  }

  /// Get cached climate data with freshness info.
  Future<CachedData<Map<String, dynamic>>?> getCachedClimate(
    double lat,
    double lon, {
    String prefix = 'current',
  }) async {
    final key = _cacheKey(lat, lon, prefix: prefix);
    final row = await _dao.getCached(key);
    if (row == null) return null;

    try {
      return CachedData<Map<String, dynamic>>(
        data: Map<String, dynamic>.from(jsonDecode(row.data) as Map),
        cachedAt: row.cachedAt, // Already a DateTime — no parsing needed
        staleDuration: prefix == 'historical'
            ? CacheConstants.historicalStaleDuration
            : CacheConstants.climateStaleDuration,
        expireDuration: prefix == 'historical'
            ? CacheConstants.historicalExpireDuration
            : CacheConstants.climateExpireDuration,
      );
    } catch (_) {
      return null;
    }
  }

  /// Cache climate data.
  Future<void> cacheClimateData(
    double lat,
    double lon,
    Map<String, dynamic> data, {
    String prefix = 'current',
  }) async {
    final key = _cacheKey(lat, lon, prefix: prefix);
    await _dao.cache(key, jsonEncode(data));
  }

  /// Clear all cached climate data.
  Future<void> clearAll() => _dao.clearAll();
}
