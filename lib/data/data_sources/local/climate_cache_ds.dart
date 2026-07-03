import 'dart:convert';
import '../../../core/constants/cache_constants.dart';
import '../../../core/utils/cache_manager.dart';
import 'app_database.dart';

class ClimateCacheDataSource {
  final ClimateDao _dao;
  ClimateCacheDataSource({required ClimateDao dao}) : _dao = dao;
  String _cacheKey(double lat, double lon, {String prefix = 'current'}) {
    final decimals = prefix == 'historical' ? 1 : 2;
    final latKey = lat.toStringAsFixed(decimals);
    final lonKey = lon.toStringAsFixed(decimals);
    return '${prefix}_${latKey}_$lonKey';
  }

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
        cachedAt: row.cachedAt,
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

  Future<void> cacheClimateData(
    double lat,
    double lon,
    Map<String, dynamic> data, {
    String prefix = 'current',
  }) async {
    final key = _cacheKey(lat, lon, prefix: prefix);
    await _dao.cache(key, jsonEncode(data));
  }

  Future<void> clearAll() => _dao.clearAll();
}
