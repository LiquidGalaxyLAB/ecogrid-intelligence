part of '../app_database.dart';

@DriftAccessor(tables: [AiInsightCacheTable])
class AiCacheDao extends DatabaseAccessor<AppDatabase> with _$AiCacheDaoMixin {
  AiCacheDao(super.db);

  /// Returns the cached insight row for the given key, or null if not cached.
  Future<AiInsightCacheTableData?> getCached(String key) => (select(
    aiInsightCacheTable,
  )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();

  /// Inserts or replaces an AI insight, optionally storing the CVS score
  /// so that cache invalidation can detect significant score drift later.
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
