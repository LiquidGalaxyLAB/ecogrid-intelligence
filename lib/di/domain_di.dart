import 'package:get_it/get_it.dart';
import '../domain/usecases/ai/services/generate_plant_insight_usecase.dart';
import '../domain/usecases/ai/services/generate_regional_insight_usecase.dart';
import '../domain/usecases/ai/services/generate_scenario_analysis_usecase.dart';
import '../domain/usecases/ai/services/generate_trend_insight_usecase.dart';
import '../domain/usecases/ai/services/start_plant_chat_usecase.dart';
import '../domain/usecases/ai/services/send_chat_message_usecase.dart';
import '../domain/usecases/climate/services/get_multi_year_trend_usecase.dart';
import '../domain/usecases/cvs/services/get_cvs_for_plant_usecase.dart';
import '../domain/usecases/cvs/services/get_cached_cvs_usecase.dart';
import '../domain/usecases/cvs/services/pre_compute_all_scores_usecase.dart';
import '../domain/usecases/cvs/services/get_plants_by_risk_level_usecase.dart';
import '../domain/usecases/cvs/services/count_plants_by_risk_level_usecase.dart';
import '../domain/usecases/cvs/services/get_unified_score_usecase.dart';
import '../domain/usecases/plant/services/get_all_plants_usecase.dart';
import '../domain/usecases/plant/services/get_plants_by_region_usecase.dart';
import '../domain/usecases/plant/services/search_plants_usecase.dart';
import '../domain/usecases/plant/services/search_regions_usecase.dart';

// Init Bloc UseCases
import '../domain/usecases/cvs/bloc/init_cvs_bloc_usecase.dart';
import '../domain/usecases/lg/bloc/init_lg_bloc_usecase.dart';
import '../domain/usecases/plant/bloc/init_plant_bloc_usecase.dart';

final sl = GetIt.instance;

void initDomain() {
  sl.registerLazySingleton(() => GeneratePlantInsightUsecase(sl()));
  sl.registerLazySingleton(() => GenerateRegionalInsightUsecase(sl()));
  sl.registerLazySingleton(() => GenerateScenarioAnalysisUsecase(sl()));
  sl.registerLazySingleton(() => GenerateTrendInsightUsecase(sl()));
  sl.registerLazySingleton(() => StartPlantChatUsecase(sl()));
  sl.registerLazySingleton(() => SendChatMessageUsecase(sl()));

  sl.registerLazySingleton(() => GetMultiYearTrendUsecase(sl()));

  sl.registerLazySingleton(() => GetCvsForPlantUsecase(sl()));
  sl.registerLazySingleton(() => GetCachedCvsUsecase(sl()));
  sl.registerLazySingleton(() => PreComputeAllScoresUsecase(sl()));
  sl.registerLazySingleton(() => GetPlantsByRiskLevelUsecase(sl()));
  sl.registerLazySingleton(() => CountPlantsByRiskLevelUsecase(sl()));
  sl.registerLazySingleton(() => GetUnifiedScoreUsecase(sl()));

  sl.registerLazySingleton(() => GetAllPlantsUsecase(sl()));
  sl.registerLazySingleton(() => GetPlantsByRegionUsecase(sl()));
  sl.registerLazySingleton(() => SearchPlantsUsecase(sl()));
  sl.registerLazySingleton(() => SearchRegionsUsecase(sl()));

  // Register Init Bloc UseCases
  sl.registerLazySingleton(() => InitCvsBlocUseCase(sl()));
  sl.registerLazySingleton(() => InitLgBlocUseCase(sl()));
  sl.registerLazySingleton(() => InitPlantBlocUseCase(sl()));
}
