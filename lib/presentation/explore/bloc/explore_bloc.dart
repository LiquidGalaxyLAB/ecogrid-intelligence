import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../core/resources/app_state.dart';
import '../../../domain/model/region.dart';
import '../../../service/lg_service.dart';
import '../../../domain/model/power_plant.dart';
import '../../../core/enums/risk_level.dart';
import '../../../core/enums/stress_filter.dart';
import '../../../core/enums/lg_display_mode.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../core/utils/region_boundary_service.dart';
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
    // restartable() cancels the previous handler (including its emit.forEach)
    // when a new event of the same type arrives. Without this, switching
    // regions while a plant stream is still open causes the new region event
    // to be queued forever behind the old emit.forEach — so the LG never
    // flies to the new location.
    on<ExploreRegionLoaded>(_onRegionLoaded, transformer: restartable());
    on<ExploreFilterChanged>(_onFilterChanged);
    on<ExploreGlobalLoaded>(_onGlobalLoaded, transformer: restartable());
    on<ExploreSearchQueryChanged>(_onSearchQueryChanged);
    on<ExploreLoadMore>(_onLoadMore);
    on<ExploreRiskFilterChanged>(_onRiskFilterChanged);
    on<ExploreGenerateRegionalInsight>(_onGenerateRegionalInsight);
    on<ExploreLGRestoreRequested>(_onLGRestoreRequested, transformer: restartable());
    on<ExploreStartOrbit>(_onStartOrbit);
    on<ExploreStopOrbit>(_onStopOrbit);
    on<ExploreSetOrbitReady>(_onSetOrbitReady);
    on<ExploreDismissInsight>((event, emit) async {
      if (state is AppSuccess<ExploreData>) {
        final data = (state as AppSuccess<ExploreData>).data!;
        emit(AppSuccess(data.copyWith(clearAiInsight: true)));
        
        final plants = data.filteredPlants;
        final region = data.region!;
        
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
                    ' () - Score: ',
              )
              .toList();
        }
        
        final settingsResult = await lgService.loadSettings();
        int rightmostScreen = 1;
        if (settingsResult is DataSuccess) {
          rightmostScreen = settingsResult.data!.rightmostScreen;
        }
        
        final balloonKml = KmlUtils.slaveScreenBalloon(
          regionName: region.name,
          lat: region.centerLat,
          lon: region.centerLon,
          totalPlants: plants.length,
          highRiskCount: highCount,
          mediumRiskCount: mediumCount,
          lowRiskCount: lowCount,
          dominantRisk: dominantRisk,
          top3Plants: top3,
        );
        await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);
      }
    });
  }

  @override
  Future<void> close() {
    lgService.stopRegionalOrbit();
    return super.close();
  }

  Future<void> _onRegionLoaded(
    ExploreRegionLoaded event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    // Auto-stop any running regional orbit when switching regions.
    await lgService.stopRegionalOrbit();

    emit(const AppLoading<ExploreData>());
    initCvsBlocUseCase();
    lgService.setCurrentRegion(event.region.name);
    lgService.setCurrentMode(LGDisplayMode.regionOverview);
    if (lgService.connectionStatus == ConnectionStatus.connected) {
      await lgService.clearKml();
      final latDiff = event.region.maxLat - event.region.minLat;
      final lonDiff = event.region.maxLon - event.region.minLon;
      final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
      double optimalRange = maxDiff * 111000.0 * 1.5;
      if (optimalRange < 500000) optimalRange = 500000;
      if (optimalRange > 12000000) optimalRange = 12000000;

      await lgService.flyTo(
        event.region.centerLat,
        event.region.centerLon,
        0,
        0,
        45, // Use 45 tilt for regions to avoid looking into the sky
        optimalRange,
      );

      // We wait 6 seconds for the initial flyTo animation to finish before
      // enabling the orbit button, ensuring the camera has arrived.
      Future.delayed(const Duration(seconds: 6), () {
        if (!isClosed) {
          add(const ExploreSetOrbitReady());
        }
      });

      // Fetch real country boundary polygon from OpenStreetMap (Nominatim) in the background
      // so it doesn't block the UI from immediately loading the power plant list.
      final currentContext = 'explore_region_';
      lgService.setKmlContext(currentContext);
      Future.microtask(() async {
        final regionKml = await RegionBoundaryService.fetchBoundaryKml(
          regionName: event.region.nominatimQuery ?? event.region.name,
          displayName: event.region.displayName ?? event.region.name,
          minLat: event.region.minLat,
          minLon: event.region.minLon,
          maxLat: event.region.maxLat,
          maxLon: event.region.maxLon,
          countries: event.region.countries,
          preFetchedGeoJson: event.region.geoJson,
        );
        if (lgService.connectionStatus == ConnectionStatus.connected && lgService.kmlContext == currentContext) {
          await lgService.sendKmlToMaster(regionKml);
        }
      });
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
          final currentContext = 'explore_region_';
          lgService.setKmlContext(currentContext);
          Future.microtask(() async {
            final regionKml = await RegionBoundaryService.fetchBoundaryKml(
              regionName: event.region.nominatimQuery ?? event.region.name,
              displayName: event.region.displayName ?? event.region.name,
              minLat: event.region.minLat,
              minLon: event.region.minLon,
              maxLat: event.region.maxLat,
              maxLon: event.region.maxLon,
              countries: event.region.countries,
              preFetchedGeoJson: event.region.geoJson,
            );
            await preComputeAllScoresUsecase(plants);
            if (lgService.connectionStatus == ConnectionStatus.connected && lgService.kmlContext == currentContext) {
              await lgService.sendKmlToMaster(regionKml);
            }
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
    bool updateMaster = true,
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
    final balloonKml = KmlUtils.slaveScreenBalloon(
      regionName: region.name,
      lat: region.centerLat,
      lon: region.centerLon,
      totalPlants: plants.length,
      highRiskCount: highCount,
      mediumRiskCount: mediumCount,
      lowRiskCount: lowCount,
      dominantRisk: dominantRisk,
      top3Plants: top3,
    );
    if (lgService.connectionStatus != ConnectionStatus.connected) return;
    await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);
    if (updateMaster) {
      final masterRegionKml = await RegionBoundaryService.fetchBoundaryKml(
        regionName: region.nominatimQuery ?? region.name,
        displayName: region.displayName ?? region.name,
        minLat: region.minLat,
        minLon: region.minLon,
        maxLat: region.maxLat,
        maxLon: region.maxLon,
        countries: region.countries,
      );
      await lgService.sendKmlToMaster(masterRegionKml);
    }
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
    );
  }

  Future<void> _onGlobalLoaded(
    ExploreGlobalLoaded event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
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

    if (data.region != null) {
      final settingsResult = await lgService.loadSettings();
      int rightmostScreen = LGSettings.empty.rightmostScreen;
      if (settingsResult is DataSuccess<LGSettings>) {
        rightmostScreen = settingsResult.data!.rightmostScreen;
      }
      
      final loadingKml = KmlUtils.regionalAiInsightBalloon(
        regionName: data.region!.displayName ?? data.region!.name,
        aiInsight: "Generating AI Regional Insight... Please wait.",
        lat: data.region!.centerLat,
        lon: data.region!.centerLon,
      );
      if (lgService.connectionStatus == ConnectionStatus.connected) {
        await lgService.showBalloonOnSlave(rightmostScreen, loadingKml);
      }
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
          final settingsResult = await lgService.loadSettings();
          int rightmostScreen = LGSettings.empty.rightmostScreen;
          if (settingsResult is DataSuccess<LGSettings>) {
            rightmostScreen = settingsResult.data!.rightmostScreen;
          }
          
          final insightKml = KmlUtils.regionalAiInsightBalloon(
            regionName: currentData.region!.displayName ?? currentData.region!.name,
            aiInsight: insight,
            lat: currentData.region!.centerLat,
            lon: currentData.region!.centerLon,
          );
          if (lgService.connectionStatus == ConnectionStatus.connected) {
            await lgService.showBalloonOnSlave(rightmostScreen, insightKml);
          }
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

  Future<void> _onStartOrbit(
    ExploreStartOrbit event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    if (state is AppSuccess<ExploreData>) {
      final data = (state as AppSuccess<ExploreData>).data!;
      emit(AppSuccess(data.copyWith(isOrbiting: true)));
      
      if (data.region != null) {
        final latDiff = data.region!.maxLat - data.region!.minLat;
        final lonDiff = data.region!.maxLon - data.region!.minLon;
        final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
        // EXACT same range as _onRegionLoaded flyTo — no position change.
        double optimalRange = maxDiff * 111000.0 * 1.5;
        if (optimalRange < 500000) optimalRange = 500000;
        if (optimalRange > 12000000) optimalRange = 12000000;

        const double orbitTilt = 45.0;
        
        try {
          // Just start orbiting from the current camera position.
          // NO flyTo, NO zoom change — heading rotates, everything else stays.
          await lgService.startRegionalOrbit(
            data.region!.centerLat,
            data.region!.centerLon,
            optimalRange,
            orbitTilt,
          );
        } catch (e) {
          debugPrint('[LG] Failed to start region orbit: $e');
          emit(AppSuccess(data.copyWith(isOrbiting: false)));
        }
      }
    }
  }

  Future<void> _onStopOrbit(
    ExploreStopOrbit event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    await lgService.stopRegionalOrbit();
    if (state is AppSuccess<ExploreData>) {
      final data = (state as AppSuccess<ExploreData>).data!;
      emit(AppSuccess(data.copyWith(isOrbiting: false)));
    }
  }

  Future<void> _onSetOrbitReady(
    ExploreSetOrbitReady event,
    Emitter<AppState<ExploreData>> emit,
  ) async {
    if (state is AppSuccess<ExploreData>) {
      final data = (state as AppSuccess<ExploreData>).data!;
      emit(AppSuccess(data.copyWith(isOrbitReady: true)));
    }
  }
}
