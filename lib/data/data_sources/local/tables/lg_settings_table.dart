import 'package:drift/drift.dart';

class LgSettingsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get host => text()();
  IntColumn get port => integer()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  IntColumn get screenCount => integer()();
  @override
  String get tableName => 'lg_settings';
  @override
  Set<Column> get primaryKey => {id};
}
