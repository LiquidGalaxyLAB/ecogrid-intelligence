import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../data/data_sources/local/app_database.dart';
import '../data/data_sources/local/power_plant_local_ds.dart';
import '../data/data_sources/local/climate_cache_ds.dart';
import '../data/data_sources/local/settings_local_ds.dart';
import '../data/data_sources/remote/open_meteo_remote_ds.dart';
import '../data/data_sources/remote/ai_data_source.dart';
import '../data/data_sources/remote/gemini_remote_ds.dart';
import '../data/data_sources/remote/lg_remote_ds.dart';

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
  final dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.apiTimeout,
      receiveTimeout: ApiConstants.apiTimeout,
    ),
  );
  sl.registerLazySingleton(() => dio);

  final db = AppDatabase();
  sl.registerLazySingleton(() => db);

  sl.registerLazySingleton(() => PowerPlantLocalDataSource());
  sl.registerLazySingleton(() => ClimateCacheDataSource(dao: db.climateDao));
  sl.registerLazySingleton(() => SettingsLocalDataSource(dao: db.settingsDao));
  sl.registerLazySingleton(() => OpenMeteoRemoteDataSource(dio: sl()));
  sl.registerLazySingleton<AIDataSource>(() => GeminiRemoteDataSource());
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
