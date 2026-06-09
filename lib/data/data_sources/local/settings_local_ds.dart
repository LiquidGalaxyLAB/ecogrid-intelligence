// ignore_for_file: prefer_initializing_formals

import 'package:ecogrid_intelligence/domain/model/lg_settings.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/app_database.dart';

/// Local data source for persisting LG SSH settings.
///
/// Always stores exactly one row (id = 1) via an upsert.
class SettingsLocalDataSource {
  final SettingsDao _dao;

  SettingsLocalDataSource({required SettingsDao dao}) : _dao = dao;

  Future<void> saveSettings(LGSettings settings) => _dao.saveSettings(
    host: settings.host,
    port: settings.port,
    username: settings.username,
    password: settings.password,
    screenCount: settings.screenCount,
  );

  /// Loads settings from the database. Returns [LGSettings.empty] if no
  /// settings have been saved yet.
  Future<LGSettings> loadSettings() async {
    final row = await _dao.getSettings();
    if (row == null) return LGSettings.empty;

    return LGSettings(
      host: row.host,
      port: row.port,
      username: row.username,
      password: row.password,
      screenCount: row.screenCount,
    );
  }
}
