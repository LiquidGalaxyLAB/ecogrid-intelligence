part of '../app_database.dart';

@DriftAccessor(tables: [AiInsightCacheTable])
class AiCacheDao extends DatabaseAccessor<AppDatabase> with _$AiCacheDaoMixin {
  AiCacheDao(super.db);
  Future<AiInsightCacheTableData?> getCached(String key) => (select(
    aiInsightCacheTable,
  )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
  Future<void> cache(String key, String insight, double? cvsScore) =>
      into(aiInsightCacheTable).insertOnConflictUpdate(
        AiInsightCacheTableCompanion(
          cacheKey: Value(key),
          insight: Value(insight),
          cachedAt: Value(DateTime.now()),
          cvsScore: Value(cvsScore),
        ),
      );
}
