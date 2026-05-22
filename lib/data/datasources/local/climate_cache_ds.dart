import 'package:hive/hive.dart';
import 'package:ecogrid_intelligence/core/constants/app_constants.dart';
import 'package:ecogrid_intelligence/core/utils/cache_manager.dart';

/// Local cache data source for climate data using Hive + staling.
class ClimateCacheDataSource {
  final Box box;

  ClimateCacheDataSource({required this.box});

  /// Generate a cache key from coordinates.
  String _cacheKey(double lat, double lon, {String prefix = 'current'}) {
    // Round to 2 decimal places for spatial bucketing
    final latKey = lat.toStringAsFixed(2);
    final lonKey = lon.toStringAsFixed(2);
    return '${prefix}_${latKey}_$lonKey';
  }

  /// Get cached climate data with freshness info.
  CachedData<Map<String, dynamic>>? getCachedClimate(double lat, double lon,
      {String prefix = 'current'}) {
    final key = _cacheKey(lat, lon, prefix: prefix);
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return CachedData<Map<String, dynamic>>(
        data: Map<String, dynamic>.from(map['data'] as Map),
        cachedAt: DateTime.parse(map['cachedAt'] as String),
        staleDuration: prefix == 'historical'
            ? AppConstants.historicalStaleDuration
            : AppConstants.climateStaleDuration,
        expireDuration: prefix == 'historical'
            ? AppConstants.historicalExpireDuration
            : AppConstants.climateExpireDuration,
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
    await box.put(key, {
      'data': data,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Clear all cached climate data.
  Future<void> clearAll() async {
    await box.clear();
  }
}
