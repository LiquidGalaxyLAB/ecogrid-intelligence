import 'package:drift/drift.dart';

class ClimateCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  String get tableName => 'climate_cache';
  @override
  Set<Column> get primaryKey => {cacheKey};
}
