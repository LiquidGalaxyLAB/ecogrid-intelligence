part of '../app_database.dart';

@DriftAccessor(tables: [ClimateCacheTable])
class ClimateDao extends DatabaseAccessor<AppDatabase> with _$ClimateDaoMixin {
  ClimateDao(super.db);

  /// Returns the cached row for the given key, or null if not cached.
  Future<ClimateCacheTableData?> getCached(String key) => (select(
    climateCacheTable,
  )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();

  /// Inserts or replaces climate data for the given cache key.
  Future<void> cache(String key, String jsonData) =>
      into(climateCacheTable).insertOnConflictUpdate(
        ClimateCacheTableCompanion(
          cacheKey: Value(key),
          data: Value(jsonData),
          cachedAt: Value(DateTime.now()),
        ),
      );

  /// Clears the entire climate cache.
  Future<void> clearAll() => delete(climateCacheTable).go();
}
