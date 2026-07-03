import 'package:get_it/get_it.dart';
import '../presentation/home/bloc/home_bloc.dart';
import '../presentation/explore/bloc/explore_bloc.dart';
import '../presentation/plant_detail/bloc/plant_detail_bloc.dart';
import '../presentation/lg_connection/bloc/lg_connection_bloc.dart';
import '../presentation/home/bloc/search_bloc.dart';

final sl = GetIt.instance;
void initPresentation() {
  sl.registerFactory(() => HomeBloc(initPlantBlocUseCase: sl()));
  sl.registerFactory(
    () => ExploreBloc(
      lgService: sl(),
      initCvsBlocUseCase: sl(),
      getPlantsByRegionUsecase: sl(),
      getAllPlantsUsecase: sl(),
      preComputeAllScoresUsecase: sl(),
      getPlantsByRiskLevelUsecase: sl(),
      countPlantsByRiskLevelUsecase: sl(),
      getUnifiedScoreUsecase: sl(),
      generateRegionalInsightUsecase: sl(),
      getCachedCvsUsecase: sl(),
      getCvsForPlantUsecase: sl(),
    ),
  );
  sl.registerFactory(
    () => PlantDetailBloc(
      lgService: sl(),
      getUnifiedScoreUsecase: sl(),
      getCvsForPlantUsecase: sl(),
      generatePlantInsightUsecase: sl(),
      generateScenarioAnalysisUsecase: sl(),
      getMultiYearTrendUsecase: sl(),
      generateTrendInsightUsecase: sl(),
      startPlantChatUsecase: sl(),
      sendChatMessageUsecase: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => LGConnectionBloc(
      lgService: sl(),
      sshService: sl(),
      initLgBlocUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => SearchBloc(searchPlantsUsecase: sl(), searchRegionsUsecase: sl()),
  );
}
