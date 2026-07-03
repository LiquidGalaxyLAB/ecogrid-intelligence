part of '../app_database.dart';

@DriftAccessor(tables: [LgSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);
  Future<LgSettingsTableData?> getSettings() =>
      (select(lgSettingsTable)..where((t) => t.id.equals(1))).getSingleOrNull();
  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
    required int screenCount,
  }) => into(lgSettingsTable).insertOnConflictUpdate(
    LgSettingsTableCompanion(
      id: const Value(1),
      host: Value(host),
      port: Value(port),
      username: Value(username),
      password: Value(password),
      screenCount: Value(screenCount),
    ),
  );
}
