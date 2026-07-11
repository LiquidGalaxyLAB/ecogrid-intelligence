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
}
