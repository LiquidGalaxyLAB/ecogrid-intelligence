part of '../app_database.dart';

@DriftAccessor(tables: [ClimateCacheTable])
class ClimateDao extends DatabaseAccessor<AppDatabase> with _$ClimateDaoMixin {
  ClimateDao(super.db);
  Future<ClimateCacheTableData?> getCached(String key) => (select(
    climateCacheTable,
  )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
  Future<void> cache(String key, String jsonData) =>
      into(climateCacheTable).insertOnConflictUpdate(
        ClimateCacheTableCompanion(
          cacheKey: Value(key),
          data: Value(jsonData),
          cachedAt: Value(DateTime.now()),
        ),
      );
  Future<void> clearAll() => delete(climateCacheTable).go();
}
