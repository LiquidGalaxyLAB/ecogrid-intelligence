import 'package:get_it/get_it.dart';
import '../service/lg_service.dart';
import '../service/ssh_service.dart';
import '../service/speech_to_text_service.dart';
import '../service/tts_service.dart';
import '../service/tour_service.dart';
import '../presentation/explore/bloc/explore_bloc.dart';
import '../presentation/home/bloc/home_bloc.dart';
import '../presentation/home/bloc/search_bloc.dart';
import '../presentation/lg_connection/bloc/lg_connection_bloc.dart';
import '../presentation/plant_detail/bloc/plant_detail_bloc.dart';
import 'di_local.dart';
import 'di_network.dart';
import 'di_repository.dart';
import 'di_usecases.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  _registerCoreDependencies();
  registerLocalDependencies();
  registerNetworkDependencies();
  registerRepositoryDependencies();
  registerUsecaseDependencies();
  _registerPresentationDependencies();
}

void _registerCoreDependencies() {
  sl.registerLazySingleton(() => SSHService());
  sl.registerLazySingleton(() => TTSService());
  sl.registerLazySingleton(() => SpeechToTextService());
  sl.registerLazySingleton<LGService>(
    () => LGService(sshService: sl(), settingsDataSource: sl()),
  );
  sl.registerLazySingleton<TourService>(() => TourService());
}

void _registerPresentationDependencies() {
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
