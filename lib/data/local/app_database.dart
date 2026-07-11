import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/lg_settings_table.dart';
import 'tables/climate_cache_table.dart';
import 'tables/ai_insight_cache_table.dart';
part 'dao/settings_dao.dart';
part 'dao/climate_dao.dart';
part 'dao/ai_cache_dao.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [LgSettingsTable, ClimateCacheTable, AiInsightCacheTable],
  daos: [SettingsDao, ClimateDao, AiCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ecogrid.db'));
    return NativeDatabase.createInBackground(file);
  });
}
