import 'package:get_it/get_it.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/generate_plant_insight_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/generate_regional_insight_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/generate_scenario_analysis_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/generate_trend_insight_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/start_plant_chat_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/ai/send_chat_message_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/climate/get_current_climate_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/climate/get_historical_climate_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/climate/get_forecast_climate_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/climate/get_multi_year_trend_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/get_cvs_for_plant_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/compute_instant_cvs_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/get_cached_cvs_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/pre_compute_all_scores_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/get_plants_by_risk_level_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/count_plants_by_risk_level_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/get_unified_score_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/cvs/clear_cvs_cache_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/connect_lg_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/disconnect_lg_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/fly_to_region_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/send_kml_to_master_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/clear_master_screen_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/send_kml_to_slave_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/show_balloon_on_slave_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/clear_balloon_on_slave_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/start_orbit_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/stop_orbit_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/clear_kml_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/reboot_lg_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/set_refresh_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/save_settings_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/lg/load_settings_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/plant/get_all_plants_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/plant/get_plants_by_region_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/plant/search_plants_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/plant/search_regions_usecase.dart';
import 'package:ecogrid_intelligence/domain/usecases/plant/get_plant_by_id_usecase.dart';

final sl = GetIt.instance;

void initDomain() {
  sl.registerLazySingleton(() => GeneratePlantInsightUsecase(sl()));
  sl.registerLazySingleton(() => GenerateRegionalInsightUsecase(sl()));
  sl.registerLazySingleton(() => GenerateScenarioAnalysisUsecase(sl()));
  sl.registerLazySingleton(() => GenerateTrendInsightUsecase(sl()));
  sl.registerLazySingleton(() => StartPlantChatUsecase(sl()));
  sl.registerLazySingleton(() => SendChatMessageUsecase(sl()));

  sl.registerLazySingleton(() => GetCurrentClimateUsecase(sl()));
  sl.registerLazySingleton(() => GetHistoricalClimateUsecase(sl()));
  sl.registerLazySingleton(() => GetForecastClimateUsecase(sl()));
  sl.registerLazySingleton(() => GetMultiYearTrendUsecase(sl()));

  sl.registerLazySingleton(() => GetCvsForPlantUsecase(sl()));
  sl.registerLazySingleton(() => ComputeInstantCvsUsecase(sl()));
  sl.registerLazySingleton(() => GetCachedCvsUsecase(sl()));
  sl.registerLazySingleton(() => PreComputeAllScoresUsecase(sl()));
  sl.registerLazySingleton(() => GetPlantsByRiskLevelUsecase(sl()));
  sl.registerLazySingleton(() => CountPlantsByRiskLevelUsecase(sl()));
  sl.registerLazySingleton(() => GetUnifiedScoreUsecase(sl()));
  sl.registerLazySingleton(() => ClearCvsCacheUsecase(sl()));

  sl.registerLazySingleton(() => ConnectLgUsecase(sl()));
  sl.registerLazySingleton(() => DisconnectLgUsecase(sl()));
  sl.registerLazySingleton(() => FlyToRegionUsecase(sl()));
  sl.registerLazySingleton(() => SendKmlToMasterUsecase(sl()));
  sl.registerLazySingleton(() => ClearMasterScreenUsecase(sl()));
  sl.registerLazySingleton(() => SendKmlToSlaveUsecase(sl()));
  sl.registerLazySingleton(() => ShowBalloonOnSlaveUsecase(sl()));
  sl.registerLazySingleton(() => ClearBalloonOnSlaveUsecase(sl()));
  sl.registerLazySingleton(() => StartOrbitUsecase(sl()));
  sl.registerLazySingleton(() => StopOrbitUsecase(sl()));
  sl.registerLazySingleton(() => ClearKmlUsecase(sl()));
  sl.registerLazySingleton(() => RebootLgUsecase(sl()));
  sl.registerLazySingleton(() => SetRefreshUsecase(sl()));
  sl.registerLazySingleton(() => SaveSettingsUsecase(sl()));
  sl.registerLazySingleton(() => LoadSettingsUsecase(sl()));

  sl.registerLazySingleton(() => GetAllPlantsUsecase(sl()));
  sl.registerLazySingleton(() => GetPlantsByRegionUsecase(sl()));
  sl.registerLazySingleton(() => SearchPlantsUsecase(sl()));
  sl.registerLazySingleton(() => SearchRegionsUsecase(sl()));
  sl.registerLazySingleton(() => GetPlantByIdUsecase(sl()));
}
