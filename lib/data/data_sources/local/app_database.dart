import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ecogrid_intelligence/data/data_sources/local/tables/lg_settings_table.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/tables/climate_cache_table.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/tables/ai_insight_cache_table.dart';

// ── DAO part files (share this library, no circular import) ──
part 'dao/settings_dao.dart';
part 'dao/climate_dao.dart';
part 'dao/ai_cache_dao.dart';

// ── Generated file ────────────────────────────────────────────
part 'app_database.g.dart';

@DriftDatabase(
  tables: [LgSettingsTable, ClimateCacheTable, AiInsightCacheTable],
  daos: [SettingsDao, ClimateDao, AiCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── DAO accessors (generated into _$AppDatabase) ─────────────
  // settingsDao, climateDao, aiCacheDao are auto-generated.
}

/// Opens a persistent SQLite database in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ecogrid.db'));
    return NativeDatabase.createInBackground(file);
  });
}
