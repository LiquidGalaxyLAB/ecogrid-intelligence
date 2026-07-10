import '../../../domain/model/lg_settings.dart';
import '../app_database.dart';

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
