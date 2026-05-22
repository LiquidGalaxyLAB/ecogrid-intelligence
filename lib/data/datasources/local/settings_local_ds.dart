import 'package:hive/hive.dart';
import 'package:ecogrid_intelligence/domain/entities/lg_settings.dart';

/// Local data source for persisting LG SSH settings.
class SettingsLocalDataSource {
  final Box box;

  SettingsLocalDataSource({required this.box});

  Future<void> saveSettings(LGSettings settings) async {
    await box.put('lg_settings', {
      'host': settings.host,
      'port': settings.port,
      'username': settings.username,
      'password': settings.password,
      'screenCount': settings.screenCount,
    });
  }

  LGSettings loadSettings() {
    final data = box.get('lg_settings');
    if (data == null) return LGSettings.empty;

    final map = Map<String, dynamic>.from(data as Map);
    return LGSettings(
      host: map['host'] as String? ?? '',
      port: map['port'] as int? ?? 22,
      username: map['username'] as String? ?? 'lg',
      password: map['password'] as String? ?? '',
      screenCount: map['screenCount'] as int? ?? 5,
    );
  }
}
