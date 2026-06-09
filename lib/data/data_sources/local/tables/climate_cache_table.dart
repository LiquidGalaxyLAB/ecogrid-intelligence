import 'package:drift/drift.dart';

/// Drift table for caching climate API responses.
/// Keyed by a coordinate-derived string (e.g. "current_28.61_77.21").
class ClimateCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get data => text()(); // JSON-encoded Map<String, dynamic>
  DateTimeColumn get cachedAt => dateTime()();

  @override
  String get tableName => 'climate_cache';

  @override
  Set<Column> get primaryKey => {cacheKey};
}
