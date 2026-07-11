import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../data/local/app_database.dart';
import '../data/local/data_sources/power_plant_local_ds.dart';
import '../data/local/data_sources/climate_cache_ds.dart';
import '../data/local/data_sources/settings_local_ds.dart';
import '../data/remote/data_sources/open_meteo_remote_ds.dart';
import '../data/remote/data_sources/ai_data_source.dart';
import '../data/remote/data_sources/gemini_remote_ds.dart';
import '../data/remote/data_sources/lg_remote_ds.dart';
import '../domain/repository/power_plant_repository.dart';
import '../domain/repository/climate_repository.dart';
import '../domain/repository/cvs_repository.dart';
import '../domain/repository/ai_repository.dart';
import '../data/repository/power_plant_repository_impl.dart';
import '../data/repository/climate_repository_impl.dart';
import '../data/repository/cvs_repository_impl.dart';
import '../data/repository/ai_repository_impl.dart';

final sl = GetIt.instance;
void initData() {
  final dio = ApiClient.createDio();
  dio.options.connectTimeout = ApiConstants.apiTimeout;
  dio.options.receiveTimeout = ApiConstants.apiTimeout;
  sl.registerLazySingleton(() => dio);
  final db = AppDatabase();
  sl.registerLazySingleton(() => db);
  sl.registerLazySingleton(() => PowerPlantLocalDataSource());
  sl.registerLazySingleton(() => ClimateCacheDataSource(dao: db.climateDao));
  sl.registerLazySingleton(() => SettingsLocalDataSource(dao: db.settingsDao));
  sl.registerLazySingleton(() => OpenMeteoRemoteDataSource(dio: sl()));
  sl.registerLazySingleton<AIDataSource>(() => GeminiRemoteDataSource(dio: sl()));
  sl.registerLazySingleton(() => LGRemoteDataSource(sshService: sl()));
  sl.registerLazySingleton<PowerPlantRepository>(
    () => PowerPlantRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ClimateRepository>(
    () => ClimateRepositoryImpl(remoteDataSource: sl(), cacheDataSource: sl()),
  );
  sl.registerLazySingleton<CvsRepository>(
    () => CvsRepositoryImpl(climateRepository: sl()),
  );
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(dataSource: sl(), aiCacheDao: db.aiCacheDao),
  );
}
