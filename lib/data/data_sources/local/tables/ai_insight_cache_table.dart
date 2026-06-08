import 'package:drift/drift.dart';

/// Drift table for caching AI-generated insight strings.
/// Keyed by a hash of plant name or region name.
class AiInsightCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get insight => text()();
  DateTimeColumn get cachedAt => dateTime()();
  RealColumn get cvsScore => real().nullable()();

  @override
  String get tableName => 'ai_insight_cache';

  @override
  Set<Column> get primaryKey => {cacheKey};
}
