import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/local/app_database.dart';
import '../data/local/data_sources/climate_cache_ds.dart';
import '../data/local/data_sources/power_plant_local_ds.dart';
import '../data/local/data_sources/settings_local_ds.dart';
import 'dependency_injection.dart';

void registerLocalDependencies() {
  final database = AppDatabase();
  sl.registerLazySingleton(() => database);
  sl.registerLazySingleton(() => PowerPlantLocalDataSource());
  sl.registerLazySingleton(
    () => ClimateCacheDataSource(dao: database.climateDao),
  );
  sl.registerLazySingleton(
    () => SettingsLocalDataSource(dao: database.settingsDao),
  );

  // Secure storage for API keys
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
}
