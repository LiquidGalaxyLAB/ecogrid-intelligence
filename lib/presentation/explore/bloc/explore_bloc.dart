import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/resources/app_state.dart';
import '../../../domain/model/region.dart';
import '../../../service/lg_service.dart';
import '../../../domain/model/power_plant.dart';
import '../../../core/enums/risk_level.dart';
import '../../../core/enums/stress_filter.dart';
import '../../../core/enums/lg_display_mode.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../domain/model/lg_settings.dart';
import '../../../domain/usecases/cvs/bloc/init_cvs_bloc_usecase.dart';
import '../../../domain/usecases/plant/services/get_plants_by_region_usecase.dart';
import '../../../domain/usecases/plant/services/get_all_plants_usecase.dart';
import '../../../domain/usecases/cvs/services/get_unified_score_usecase.dart';
import '../../../domain/usecases/cvs/services/count_plants_by_risk_level_usecase.dart';
import '../../../domain/usecases/cvs/services/get_plants_by_risk_level_usecase.dart';
import '../../../domain/usecases/cvs/services/pre_compute_all_scores_usecase.dart';
import '../../../domain/usecases/cvs/services/get_cached_cvs_usecase.dart';
import '../../../domain/usecases/cvs/services/get_cvs_for_plant_usecase.dart';
import '../../../domain/usecases/ai/services/generate_regional_insight_usecase.dart';
import '../../../core/resources/data_state.dart';
import '../../../core/enums/connection_status.dart';
import 'explore_event.dart';
import 'explore_data.dart';

class ExploreBloc extends Bloc<ExploreEvent, AppState<ExploreData>> {
  final LGService lgService;
  final GetPlantsByRegionUsecase getPlantsByRegionUsecase;
  final GetAllPlantsUsecase getAllPlantsUsecase;
  final PreComputeAllScoresUsecase preComputeAllScoresUsecase;
  final GetPlantsByRiskLevelUsecase getPlantsByRiskLevelUsecase;
  final CountPlantsByRiskLevelUsecase countPlantsByRiskLevelUsecase;
  final GetUnifiedScoreUsecase getUnifiedScoreUsecase;
  final GenerateRegionalInsightUsecase generateRegionalInsightUsecase;
  final GetCachedCvsUsecase getCachedCvsUsecase;
  final GetCvsForPlantUsecase getCvsForPlantUsecase;
  final InitCvsBlocUseCase initCvsBlocUseCase;
  bool _isCancelled = false;
  ExploreBloc({
    required this.lgService,
    required this.initCvsBlocUseCase,
    required this.getPlantsByRegionUsecase,
    required this.getAllPlantsUsecase,
    required this.preComputeAllScoresUsecase,
    required this.getPlantsByRiskLevelUsecase,
    required this.countPlantsByRiskLevelUsecase,
    required this.getUnifiedScoreUsecase,
    required this.generateRegionalInsightUsecase,
    required this.getCachedCvsUsecase,
    required this.getCvsForPlantUsecase,
  }) : super(const AppLoading()) {
    on<ExploreRegionLoaded>(_onRegionLoaded);
    on<ExploreFilterChanged>(_onFilterChanged);
    on<ExploreGlobalLoaded>(_onGlobalLoaded);
    on<ExploreSearchQueryChanged>(_onSearchQueryChanged);
    on<ExploreLoadMore>(_onLoadMore);
    on<ExploreRiskFilterChanged>(_onRiskFilterChanged);
    on<ExploreGenerateRegionalInsight>(_onGenerateRegionalInsight);
    on<ExploreShowPlantsOnLG>(_onShowPlantsOnLG);
    on<ExploreLGRestoreRequested>(_onLGRestoreRequested);
    on<ExploreDismissInsight>((event, emit) {
      if (state is AppSuccess<ExploreData>) {
        final data = (state as AppSuccess<ExploreData>).data!;
        emit(AppSuccess(data.copyWith(clearAiInsight: true)));
      }
    });
  }
  Future<void> _onRegionLoaded(
    ExploreRegionLoaded event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    _isCancelled = true;
    emit(const AppLoading<ExploreData>());
    initCvsBlocUseCase();
    lgService.setCurrentRegion(event.region.name);
    lgService.setCurrentMode(LGDisplayMode.regionOverview);
    if (lgService.connectionStatus == ConnectionStatus.connected) {
      await lgService.clearKml();
      await lgService.flyTo(
        event.region.centerLat,
        event.region.centerLon,
        0,
        0,
        0,
        event.region.defaultZoom * 150000,
      );
      final regionKml = KmlUtils.regionPlacemark(
        regionName: event.region.name,
        lat: event.region.centerLat,
        lon: event.region.centerLon,
      );
      await lgService.sendKmlToMaster(regionKml);
    }
    await emit.forEach<DataState<List<PowerPlant>>>(
      getPlantsByRegionUsecase(params: event.region),
      onData: (dataState) {
        if (dataState is DataLoading<List<PowerPlant>>) {
          return const AppLoading<ExploreData>();
        } else if (dataState is DataEmpty<List<PowerPlant>>) {
          return AppSuccess<ExploreData>(
            ExploreData(
              region: event.region,
              plants: const [],
              filteredPlants: const [],
              displayLimit: 15,
            ),
          );
        } else if (dataState is DataSuccess<List<PowerPlant>>) {
          final plants = dataState.data!;
          Future.microtask(() async {
            await preComputeAllScoresUsecase(plants);
            _startBackgroundWarmer();
            await _updateRightScreenOverlay(event.region, plants);
          });
          return AppSuccess<ExploreData>(
            ExploreData(
              region: event.region,
              plants: plants,
              filteredPlants: plants,
              isLoadingInsight: false,
              displayLimit: 15,
            ),
          );
        } else {
          return AppFailure<ExploreData>(
            dataState.exception ?? Exception('Failed to load plants'),
          );
        }
      },
      onError: (error, _) => AppFailure<ExploreData>(Exception(error)),
    );
  }

  Future<void> _updateRightScreenOverlay(
    Region region,
    List<PowerPlant> plants, {
    String? aiInsight,
  }) async {
    final highRiskPlants = getPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.high,
      pageSize: plants.length,
    );
    final highCount = highRiskPlants.length;
    final mediumCount = countPlantsByRiskLevelUsecase(plants, RiskLevel.medium);
    final lowCount = countPlantsByRiskLevelUsecase(plants, RiskLevel.low);
    String dominantRisk = 'None';
    List<String> top3 = [];
    if (highRiskPlants.isNotEmpty) {
      double totalTemp = 0;
      double totalWater = 0;
      double totalWind = 0;
      for (final p in highRiskPlants) {
        final score = getUnifiedScoreUsecase(p);
        totalTemp += score.temperatureStress;
        totalWater += score.waterStress;
        totalWind += score.windStress;
      }
      if (totalTemp > totalWater && totalTemp > totalWind) {
        dominantRisk = 'Temperature/Heat';
      } else if (totalWater > totalTemp && totalWater > totalWind) {
        dominantRisk = 'Water/Drought/Flood';
      } else if (totalWind > totalTemp && totalWind > totalWater) {
        dominantRisk = 'Wind/Storms';
      } else {
        dominantRisk = 'Multiple Equal Threats';
      }
      final topPlants = highRiskPlants.take(3).toList();
      top3 = topPlants
          .map(
            (p) =>
                '${p.name} (${p.primaryFuel.displayName}) - Score: ${getUnifiedScoreUsecase(p).score.toStringAsFixed(1)}',
          )
          .toList();
    }
    final settingsResult = await lgService.loadSettings();
    int screenCount = LGSettings.empty.screenCount;
    int rightmostScreen = LGSettings.empty.rightmostScreen;
    if (settingsResult is DataSuccess<LGSettings>) {
      screenCount = settingsResult.data!.screenCount;
      rightmostScreen = settingsResult.data!.rightmostScreen;
    }
    final offsetPerSideScreen = 10.0;
    final sideScreens = (screenCount - 1) / 2;
    final rightmostLonOffset =
        region.centerLon + (offsetPerSideScreen * sideScreens);
    final adjustedLon = rightmostLonOffset > 180.0
        ? rightmostLonOffset - 360.0
        : rightmostLonOffset;
    final balloonKml = KmlUtils.slaveScreenBalloon(
      regionName: region.name,
      lat: region.centerLat,
      lon: adjustedLon,
      totalPlants: plants.length,
      highRiskCount: highCount,
      mediumRiskCount: mediumCount,
      lowRiskCount: lowCount,
      dominantRisk: dominantRisk,
      top3Plants: top3,
      aiInsight: aiInsight,
    );
    if (lgService.connectionStatus != ConnectionStatus.connected) return;
    await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);
    final masterRegionKml = KmlUtils.regionPlacemark(
      lat: region.centerLat,
      lon: region.centerLon,
      regionName: region.name,
    );
    await lgService.sendKmlToMaster(masterRegionKml);
  }

  Future<void> _onShowPlantsOnLG(
    ExploreShowPlantsOnLG event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    if (data.filteredPlants.isEmpty) return;
    lgService.setCurrentMode(LGDisplayMode.plantPlacemarks);
    await lgService.clearMasterScreen();
    final batchPlants = data.filteredPlants.take(100).toList();
    final scores = batchPlants.map((p) => getUnifiedScoreUsecase(p)).toList();
    final risks = scores.map((s) => s.riskLevel).toList();
    final kml = KmlUtils.plantPlacemarksBatch(
      plants: batchPlants,
      scores: scores,
      risks: risks,
      title: '${data.region?.name ?? "Global"} Plants',
    );
    await lgService.sendKmlToMaster(kml);
  }

  Future<void> _onLGRestoreRequested(
    ExploreLGRestoreRequested event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    if (data.region == null) return;
    lgService.setCurrentMode(LGDisplayMode.regionOverview);
    await _updateRightScreenOverlay(
      data.region!,
      data.plants,
      aiInsight: data.aiInsight,
    );
  }

  Future<void> _onGlobalLoaded(
    ExploreGlobalLoaded event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    _isCancelled = true;
    emit(const AppLoading<ExploreData>());
    initCvsBlocUseCase();
    await emit.forEach<DataState<List<PowerPlant>>>(
      getAllPlantsUsecase(),
      onData: (dataState) {
        if (dataState is DataLoading<List<PowerPlant>>) {
          return const AppLoading<ExploreData>();
        } else if (dataState is DataEmpty<List<PowerPlant>>) {
          return AppSuccess<ExploreData>(
            const ExploreData(plants: [], filteredPlants: [], displayLimit: 15),
          );
        } else if (dataState is DataSuccess<List<PowerPlant>>) {
          final plants = dataState.data!;
          Future.microtask(
            () => preComputeAllScoresUsecase(
              plants,
            ).then((_) => _startBackgroundWarmer()),
          );
          return AppSuccess<ExploreData>(
            ExploreData(
              plants: plants,
              filteredPlants: plants,
              displayLimit: 15,
            ),
          );
        } else {
          return AppFailure<ExploreData>(
            dataState.exception ?? Exception('Failed to load plants'),
          );
        }
      },
      onError: (error, _) => AppFailure<ExploreData>(Exception(error)),
    );
  }

  void _onFilterChanged(
    ExploreFilterChanged event,
    Emitter<AppState<ExploreData>> emit,
  ) {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    final typeFilter = event.clearTypeFilter
        ? null
        : (event.typeFilter ?? data.activeTypeFilter);
    final stressFilter = event.clearStressFilter
        ? null
        : (event.stressFilter ?? data.activeStressFilter);
    _isCancelled = true;
    final nextData = data.copyWith(
      activeTypeFilter: event.clearTypeFilter ? null : typeFilter,
      activeStressFilter: event.clearStressFilter ? null : stressFilter,
      displayLimit: 15,
      isScanning: false,
    );
    final filtered = _applyFilters(nextData);
    emit(AppSuccess(filtered));
    _startBackgroundWarmer();
  }

  void _onSearchQueryChanged(
    ExploreSearchQueryChanged event,
    Emitter<AppState<ExploreData>> emit,
  ) {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    final nextData = data.copyWith(searchQuery: event.query, displayLimit: 15);
    emit(AppSuccess(_applyFilters(nextData)));
  }

  void _onLoadMore(ExploreLoadMore event, Emitter<AppState<ExploreData>> emit) {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    final maxCount = data.activeRiskFilter != null
        ? data.totalFilteredCount
        : data.filteredPlants.length;
    if (data.displayLimit < maxCount) {
      emit(AppSuccess(data.copyWith(displayLimit: data.displayLimit + 15)));
    }
  }

  void _onRiskFilterChanged(
    ExploreRiskFilterChanged event,
    Emitter<AppState<ExploreData>> emit,
  ) {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    _isCancelled = true;
    final newRiskFilter = event.riskLevel == data.activeRiskFilter
        ? null
        : event.riskLevel;
    final nextData = data.copyWith(
      activeRiskFilter: newRiskFilter,
      displayLimit: 15,
      isScanning: false,
    );
    emit(AppSuccess(_applyFilters(nextData)));
    _startBackgroundWarmer();
  }

  Future<void> _onGenerateRegionalInsight(
    ExploreGenerateRegionalInsight event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    if (state is! AppSuccess<ExploreData>) return;
    final data = (state as AppSuccess<ExploreData>).data!;
    emit(AppSuccess(data.copyWith(isLoadingInsight: true)));
    final plants = data.plants;
    final highCount = countPlantsByRiskLevelUsecase(plants, RiskLevel.high);
    final mediumCount = countPlantsByRiskLevelUsecase(plants, RiskLevel.medium);
    final lowCount = countPlantsByRiskLevelUsecase(plants, RiskLevel.low);
    final riskBreakdown = {
      'High': highCount,
      'Medium': mediumCount,
      'Low': lowCount,
    };
    final highRiskPlants = getPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.high,
      pageSize: plants.length,
    );
    String dominantRisk = 'None';
    String commonType = 'None';
    List<String> top3 = [];
    if (highRiskPlants.isNotEmpty) {
      double totalTemp = 0;
      double totalWater = 0;
      double totalWind = 0;
      final typeCounts = <String, int>{};
      for (final p in highRiskPlants) {
        final score = getUnifiedScoreUsecase(p);
        totalTemp += score.temperatureStress;
        totalWater += score.waterStress;
        totalWind += score.windStress;
        final typeName = p.primaryFuel.displayName;
        typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
      }
      if (totalTemp > totalWater && totalTemp > totalWind) {
        dominantRisk = 'Temperature/Heat';
      } else if (totalWater > totalTemp && totalWater > totalWind) {
        dominantRisk = 'Water/Drought/Flood';
      } else if (totalWind > totalTemp && totalWind > totalWater) {
        dominantRisk = 'Wind/Storms';
      } else {
        dominantRisk = 'Multiple Equal Threats';
      }
      var maxCount = 0;
      for (final entry in typeCounts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          commonType = entry.key;
        }
      }
      final topPlants = highRiskPlants.take(3).toList();
      top3 = topPlants
          .map(
            (p) =>
                '${p.name} (${p.primaryFuel.displayName}) - Score: ${getUnifiedScoreUsecase(p).score.toStringAsFixed(1)}',
          )
          .toList();
    }
    final insightResult = await generateRegionalInsightUsecase(
      params: {
        'regionName': data.region?.displayName ?? data.region?.name ?? 'Global',
        'riskFilterName': data.activeRiskFilter?.name ?? 'All',
        'totalPlants': plants.length,
        'riskBreakdown': riskBreakdown,
        'dominantRiskDimension': dominantRisk,
        'commonHighRiskType': commonType,
        'top3Plants': top3,
      },
    ).last;
    if (insightResult is DataSuccess<String>) {
      final insight = insightResult.data!;
      if (state is AppSuccess<ExploreData>) {
        final currentData = (state as AppSuccess<ExploreData>).data!;
        emit(
          AppSuccess(
            currentData.copyWith(aiInsight: insight, isLoadingInsight: false),
          ),
        );
        if (currentData.region != null) {
          _updateRightScreenOverlay(
            currentData.region!,
            plants,
            aiInsight: insight,
          );
        }
      }
    } else {
      if (state is AppSuccess<ExploreData>) {
        final currentData = (state as AppSuccess<ExploreData>).data!;
        emit(AppSuccess(currentData.copyWith(isLoadingInsight: false)));
      }
    }
  }

  ExploreData _applyFilters(ExploreData data) {
    var filtered = data.plants;
    if (data.activeTypeFilter != null) {
      filtered = filtered
          .where((p) => p.primaryFuel == data.activeTypeFilter)
          .toList();
    }
    final query = data.searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) => p.searchKey.contains(query)).toList();
    }
    if (data.activeStressFilter != null) {
      filtered = filtered.where((p) {
        final cvs = getUnifiedScoreUsecase(p);
        final temp = cvs.temperatureStress;
        final water = cvs.waterStress;
        final wind = cvs.windStress;
        if (data.activeStressFilter == StressFilter.temperature) {
          return temp >= 40 && temp >= water && temp >= wind;
        }
        if (data.activeStressFilter == StressFilter.water) {
          return water >= 40 && water >= temp && water >= wind;
        }
        if (data.activeStressFilter == StressFilter.wind) {
          return wind >= 40 && wind >= temp && wind >= water;
        }
        return true;
      }).toList();
    }
    int totalFilteredCount = filtered.length;
    if (data.activeRiskFilter != null) {
      totalFilteredCount = countPlantsByRiskLevelUsecase(
        filtered,
        data.activeRiskFilter!,
      );
      filtered = getPlantsByRiskLevelUsecase(
        filtered,
        data.activeRiskFilter!,
        page: 1,
        pageSize: filtered.length,
      );
    }
    return data.copyWith(
      filteredPlants: filtered,
      totalFilteredCount: totalFilteredCount,
    );
  }

  void _startBackgroundWarmer() async {
    // Disabled background warmer as per user request to stop continuous API polling.
    // The data will be fetched on-demand when the user views a plant.
    return;
  }
}
