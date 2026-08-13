import '../data/repository/ai_repository_impl.dart';
import '../data/repository/api_key_repository_impl.dart';
import '../data/repository/climate_repository_impl.dart';
import '../data/repository/cvs_repository_impl.dart';
import '../data/repository/power_plant_repository_impl.dart';
import '../data/local/app_database.dart';
import '../domain/repository/ai_repository.dart';
import '../domain/repository/api_key_repository.dart';
import '../domain/repository/climate_repository.dart';
import '../domain/repository/cvs_repository.dart';
import '../domain/repository/power_plant_repository.dart';
import 'dependency_injection.dart';

void registerRepositoryDependencies() {
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
    () => AIRepositoryImpl(
      dataSource: sl(),
      aiCacheDao: sl<AppDatabase>().aiCacheDao,
    ),
  );
  sl.registerLazySingleton<ApiKeyRepository>(
    () => ApiKeyRepositoryImpl(secureStorage: sl()),
  );
}
