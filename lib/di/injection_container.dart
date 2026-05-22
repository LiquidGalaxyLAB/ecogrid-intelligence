import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:ecogrid_intelligence/config/app_config.dart';
import 'package:ecogrid_intelligence/core/constants/app_constants.dart';

// Domain repositories
import 'package:ecogrid_intelligence/domain/repositories/power_plant_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/climate_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/ai_repository.dart';

// Data implementations
import 'package:ecogrid_intelligence/data/repositories/power_plant_repository_impl.dart';
import 'package:ecogrid_intelligence/data/repositories/climate_repository_impl.dart';
import 'package:ecogrid_intelligence/data/repositories/lg_repository_impl.dart';
import 'package:ecogrid_intelligence/data/repositories/ai_repository_impl.dart';

// Data sources
import 'package:ecogrid_intelligence/data/datasources/local/power_plant_local_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/local/climate_cache_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/local/settings_local_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/open_meteo_remote_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/gemini_remote_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/lg_remote_ds.dart';

// Services
import 'package:ecogrid_intelligence/service/ssh_service.dart';
import 'package:ecogrid_intelligence/service/tts_service.dart';

// BLoCs
import 'package:ecogrid_intelligence/presentation/blocs/home/home_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/explore/explore_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/plant_detail/plant_detail_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/lg_connection/lg_connection_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/search/search_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ────────────────────────────────────────
  final dio = Dio(BaseOptions(
    connectTimeout: AppConfig.apiTimeout,
    receiveTimeout: AppConfig.apiTimeout,
  ));
  sl.registerLazySingleton(() => dio);

  // ─── Hive Boxes ──────────────────────────────────────
  await Hive.initFlutter();
  final plantBox = await Hive.openBox(AppConstants.plantBox);
  final climateBox = await Hive.openBox(AppConstants.climateBox);
  final settingsBox = await Hive.openBox(AppConstants.settingsBox);
  final aiInsightBox = await Hive.openBox(AppConstants.aiInsightBox);


  // ─── Services ────────────────────────────────────────
  sl.registerLazySingleton(() => SSHService());
  sl.registerLazySingleton(() => TTSService());

  // ─── Data Sources ────────────────────────────────────
  sl.registerLazySingleton(() => PowerPlantLocalDataSource(box: plantBox));
  sl.registerLazySingleton(() => ClimateCacheDataSource(box: climateBox));
  sl.registerLazySingleton(() => SettingsLocalDataSource(box: settingsBox));
  sl.registerLazySingleton(() => OpenMeteoRemoteDataSource(dio: sl()));
  sl.registerLazySingleton(() => GeminiRemoteDataSource());
  sl.registerLazySingleton(() => LGRemoteDataSource(sshService: sl()));

  // ─── Repositories ───────────────────────────────────
  sl.registerLazySingleton<PowerPlantRepository>(
    () => PowerPlantRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ClimateRepository>(
    () => ClimateRepositoryImpl(
      remoteDataSource: sl(),
      cacheDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<LGRepository>(
    () => LGRepositoryImpl(
      remoteDataSource: sl(),
      settingsDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(
      remoteDataSource: sl(),
      cacheBox: aiInsightBox,
    ),
  );

  // ─── BLoCs ──────────────────────────────────────────
  sl.registerFactory(() => HomeBloc(
        powerPlantRepository: sl(),
        lgRepository: sl(),
      ));
  sl.registerFactory(() => ExploreBloc(
        powerPlantRepository: sl(),
        climateRepository: sl(),
        lgRepository: sl(),
        aiRepository: sl(),
      ));
  sl.registerFactory(() => PlantDetailBloc(
        climateRepository: sl(),
        aiRepository: sl(),
        lgRepository: sl(),
      ));
  sl.registerFactory(() => LGConnectionBloc(lgRepository: sl()));
  sl.registerFactory(() => SearchBloc(powerPlantRepository: sl()));
}
