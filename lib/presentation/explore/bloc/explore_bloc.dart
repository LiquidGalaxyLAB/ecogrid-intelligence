// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
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
  }) : super(const ExploreInitial()) {
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
      if (state is ExploreLoaded) {
        emit((state as ExploreLoaded).copyWith(clearAiInsight: true));
      }
    });
  }

  Future<void> _onRegionLoaded(
    ExploreRegionLoaded event,
    Emitter<ExploreState> emit,
  ) async {
    _isCancelled = true; // Cancel any ongoing scan
    emit(const ExploreLoading());

    // 0. Initialize CVS state by clearing cache
    initCvsBlocUseCase();

    // 1. Track LG state (always, even if not connected)
    lgService.setCurrentRegion(event.region.name);
    lgService.setCurrentMode(LGDisplayMode.regionOverview);

    // 2. LG commands — skip silently if not connected.
    // Only explicit user button presses show the "not connected" toast.
    if (lgService.connectionStatus == ConnectionStatus.connected) {
      await lgService.clearKml();

      // FlyTo region on LG
      await lgService.flyTo(
        event.region.centerLat,
        event.region.centerLon,
        0,
        0,
        0,
        event.region.defaultZoom * 150000,
      );

      // Send Region Placemark to master screen
      final regionKml = KmlUtils.regionPlacemark(
        regionName: event.region.name,
        lat: event.region.centerLat,
        lon: event.region.centerLon,
      );
      await lgService.sendKmlToMaster(regionKml);
    }

    // Get plants in region
    final plantsResult = await getPlantsByRegionUsecase(params: event.region);

    if (plantsResult is DataSuccess<List<PowerPlant>>) {
      final plants = plantsResult.data!;
      emit(ExploreLoaded(
        region: event.region,
        plants: plants,
        filteredPlants: plants,
        isLoadingInsight: false,
        displayLimit: 15,
      ));
      await preComputeAllScoresUsecase(plants);
      _startBackgroundWarmer();
      await _updateRightScreenOverlay(event.region, plants);
    } else {
      emit(ExploreError(plantsResult.exception?.toString() ?? 'Failed to load plants'));
    }
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
    final mediumCount = countPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.medium,
    );
    final lowCount = countPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.low,
    );

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

    // Get settings and calculate rightmost screen dynamically
    final settingsResult = await lgService.loadSettings();
    int screenCount = LGSettings.empty.screenCount;
    int rightmostScreen = LGSettings.empty.rightmostScreen;

    if (settingsResult is DataSuccess<LGSettings>) {
      screenCount = settingsResult.data!.screenCount;
      rightmostScreen = settingsResult.data!.rightmostScreen;
    }

    // Calculate longitude offset dynamically based on the number of screens.
    // For 3 screens, ~10 degrees works well. For 5 screens, ~20 degrees.
    final offsetPerSideScreen = 10.0;
    final sideScreens = (screenCount - 1) / 2; // e.g. 1 side screen for 3 total
    final rightmostLonOffset =
        region.centerLon + (offsetPerSideScreen * sideScreens);

    // Cap longitude at 180 and wrap around
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

    // Skip silently if LG is not connected
    if (lgService.connectionStatus != ConnectionStatus.connected) return;

    // Send balloon to dynamically calculated rightmost screen
    await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);

    // Also, generate a huge region placemark and send it to the master screen
    final masterRegionKml = KmlUtils.regionPlacemark(
      lat: region.centerLat,
      lon: region.centerLon,
      regionName: region.name,
    );
    await lgService.sendKmlToMaster(masterRegionKml);
  }

  Future<void> _onShowPlantsOnLG(
    ExploreShowPlantsOnLG event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    if (currentState.filteredPlants.isEmpty) return;

    // Update LG State tracker
    lgService.setCurrentMode(LGDisplayMode.plantPlacemarks);

    // Clear master screen first
    await lgService.clearMasterScreen();

    // Prepare data for batch placemarks
    final batchPlants = currentState.filteredPlants.take(100).toList();
    final scores = batchPlants.map((p) => getUnifiedScoreUsecase(p)).toList();
    final risks = scores.map((s) => s.riskLevel).toList();

    final kml = KmlUtils.plantPlacemarksBatch(
      plants: batchPlants,
      scores: scores,
      risks: risks,
      title: '${currentState.region?.name ?? "Global"} Plants',
    );
    await lgService.sendKmlToMaster(kml);
  }

  /// Re-sends the region LG overlay after returning from plant detail.
  /// Only fires if the bloc still has a region loaded. No data is re-fetched.
  Future<void> _onLGRestoreRequested(
    ExploreLGRestoreRequested event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;
    if (currentState.region == null) return;

    lgService.setCurrentMode(LGDisplayMode.regionOverview);
    await _updateRightScreenOverlay(
      currentState.region!,
      currentState.plants,
      aiInsight: currentState.aiInsight,
    );
  }

  Future<void> _onGlobalLoaded(
    ExploreGlobalLoaded event,
    Emitter<ExploreState> emit,
  ) async {
    _isCancelled = true;
    emit(const ExploreLoading());

    // 0. Initialize CVS state by clearing cache
    initCvsBlocUseCase();

    final plantsResult = await getAllPlantsUsecase();

    if (plantsResult is DataSuccess<List<PowerPlant>>) {
      final plants = plantsResult.data!;
      emit(ExploreLoaded(plants: plants, filteredPlants: plants, displayLimit: 15));
      preComputeAllScoresUsecase(plants).then((_) => _startBackgroundWarmer());
    } else {
      emit(ExploreError(plantsResult.exception?.toString() ?? 'Failed to load plants'));
    }
  }

  void _onFilterChanged(
    ExploreFilterChanged event,
    Emitter<ExploreState> emit,
  ) {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    final typeFilter = event.clearTypeFilter
        ? null
        : (event.typeFilter ?? currentState.activeTypeFilter);
    final stressFilter = event.clearStressFilter
        ? null
        : (event.stressFilter ?? currentState.activeStressFilter);

    _isCancelled = true; // Cancel ongoing scan before starting new

    final nextState = currentState.copyWith(
      activeTypeFilter: event.clearTypeFilter ? null : typeFilter,
      activeStressFilter: event.clearStressFilter
          ? null
          : stressFilter,
      displayLimit: 15, // Reset pagination on new filter
      isScanning: false,
    );

    final filteredState = _applyFilters(nextState);
    emit(filteredState);

    // Restart the background warmer so it continues caching grids.
    // As new grids get cached, the filtered list grows automatically.
    _startBackgroundWarmer();
  }

  void _onSearchQueryChanged(
    ExploreSearchQueryChanged event,
    Emitter<ExploreState> emit,
  ) {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    final nextState = currentState.copyWith(
      searchQuery: event.query,
      displayLimit: 15, // Reset pagination on new search
    );

    emit(_applyFilters(nextState));
  }

  void _onLoadMore(ExploreLoadMore event, Emitter<ExploreState> emit) {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    // Increase limit by 15 if there are more plants to show
    final maxCount = currentState.activeRiskFilter != null
        ? currentState.totalFilteredCount
        : currentState.filteredPlants.length;
    if (currentState.displayLimit < maxCount) {
      emit(currentState.copyWith(displayLimit: currentState.displayLimit + 15));
    }
  }

  void _onRiskFilterChanged(
    ExploreRiskFilterChanged event,
    Emitter<ExploreState> emit,
  ) {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    _isCancelled = true;

    // If tapping the same filter, toggle it off
    final newRiskFilter = event.riskLevel == currentState.activeRiskFilter
        ? null
        : event.riskLevel;

    final nextState = currentState.copyWith(
      activeRiskFilter: newRiskFilter, // Passing null actually clears it now
      displayLimit: 15, // Reset pagination
      isScanning: false,
    );

    final filteredState = _applyFilters(nextState);
    emit(filteredState);

    _startBackgroundWarmer();
  }

  /// Generate regional insight — ONLY fires on explicit user button tap.
  Future<void> _onGenerateRegionalInsight(
    ExploreGenerateRegionalInsight event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    emit(currentState.copyWith(isLoadingInsight: true));

    final plants = currentState.plants;

    // Calculate risk breakdown
    final highCount = countPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.high,
    );
    final mediumCount = countPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.medium,
    );
    final lowCount = countPlantsByRiskLevelUsecase(
      plants,
      RiskLevel.low,
    );

    final riskBreakdown = {
      'High': highCount,
      'Medium': mediumCount,
      'Low': lowCount,
    };

    // Calculate metrics specifically for high-risk plants
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

        // Count types
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

      // Top 3 highest risk
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
        'regionName': currentState.region?.displayName ?? currentState.region?.name ?? 'Global',
        'riskFilterName': currentState.activeRiskFilter?.name ?? 'All',
        'totalPlants': plants.length,
        'riskBreakdown': riskBreakdown,
        'dominantRiskDimension': dominantRisk,
        'commonHighRiskType': commonType,
        'top3Plants': top3,
      },
    );

    if (insightResult is DataSuccess<String>) {
      if (state is ExploreLoaded) {
        final loadedState = state as ExploreLoaded;
        emit(loadedState.copyWith(aiInsight: insightResult.data!, isLoadingInsight: false));
        if (loadedState.region != null) {
          _updateRightScreenOverlay(loadedState.region!, plants, aiInsight: insightResult.data!);
        }
      }
    } else {
      if (state is ExploreLoaded) {
        emit((state as ExploreLoaded).copyWith(isLoadingInsight: false));
      }
    }
  }

  ExploreLoaded _applyFilters(ExploreLoaded state) {
    var filtered = state.plants;

    // Apply type filter
    if (state.activeTypeFilter != null) {
      filtered = filtered
          .where((p) => p.primaryFuel == state.activeTypeFilter)
          .toList();
    }

    // Apply search query locally
    final query = state.searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) => p.searchKey.contains(query)).toList();
    }

    // Apply stress filter using the unified single source of truth to prevent empty lists.
    if (state.activeStressFilter != null) {
      filtered = filtered.where((p) {
        final cvs = getUnifiedScoreUsecase(p);

        final temp = cvs.temperatureStress;
        final water = cvs.waterStress;
        final wind = cvs.windStress;

        if (state.activeStressFilter == StressFilter.temperature) {
          return temp >= 40 && temp >= water && temp >= wind;
        }
        if (state.activeStressFilter == StressFilter.water) {
          return water >= 40 && water >= temp && water >= wind;
        }
        if (state.activeStressFilter == StressFilter.wind) {
          return wind >= 40 && wind >= temp && wind >= water;
        }

        return true;
      }).toList();
    }

    // Apply risk level filter — queries the pre-computed score index
    int totalFilteredCount = filtered.length;
    if (state.activeRiskFilter != null) {
      totalFilteredCount = countPlantsByRiskLevelUsecase(
        filtered,
        state.activeRiskFilter!,
      );
      filtered = getPlantsByRiskLevelUsecase(
        filtered,
        state.activeRiskFilter!,
        page: 1,
        pageSize: filtered.length, // Get all matching, UI controls displayLimit
      );
    }

    return state.copyWith(
      filteredPlants: filtered,
      totalFilteredCount: totalFilteredCount,
    );
  }

  void _startBackgroundWarmer() async {
    _isCancelled = false;

    while (!_isCancelled && !isClosed) {
      if (state is! ExploreLoaded) break;
      final currentState = state as ExploreLoaded;

      // Find the first plant whose grid is NOT yet cached.
      // Because the cache is grid-level, scanning this ONE plant
      // will instantly verify every other plant in the same ~50km block.
      PowerPlant? nextToScan;

      for (final p in currentState.plants) {
        if (getCachedCvsUsecase(p) == null) {
          nextToScan = p;
          break;
        }
      }

      // If absolutely everything is cached, we are done scanning!
      if (nextToScan == null) {
        if (currentState.isScanning && !isClosed) {
          emit(
            _applyFilters(
              currentState,
            ).copyWith(isScanning: false, scanProgress: 1.0),
          );
        }
        break;
      }

      // If we found something to scan, ensure the UI knows we are scanning
      if (!currentState.isScanning && !isClosed) {
        emit(currentState.copyWith(isScanning: true));
      }

      // Fetch the CVS data for this plant (caches the entire grid block)
      await getCvsForPlantUsecase(params: nextToScan);

      if (_isCancelled || isClosed) break;

      // Check if the API was rate-limited (429). If so, back off.
      final cachedResult = getCachedCvsUsecase(nextToScan);
      final wasRateLimited = cachedResult != null && !cachedResult.isVerified;

      // Update the UI state with the newly cached data.
      // Do NOT re-apply filters, so the list stays exactly as it was when the user loaded it
      // (prevents jumping/switching while viewing).
      if (state is ExploreLoaded && !isClosed) {
        final latestState = state as ExploreLoaded;
        final unCachedCount = latestState.plants
            .where((p) => getCachedCvsUsecase(p) == null)
            .length;
        final progress = 1.0 - (unCachedCount / latestState.plants.length);

        emit(latestState.copyWith(scanProgress: progress, isScanning: true));
      }

      if (wasRateLimited) {
        // API returned 429 — back off for 8 seconds to let rate limit cool down
        await Future.delayed(const Duration(milliseconds: 8000));
      } else {
        // Normal delay: 3000ms = ~20 grids/min = ~40 API requests/min
        // Generous pacing to avoid timeouts on emulators with slower networking.
        await Future.delayed(const Duration(milliseconds: 3000));
      }
    }
  }
}
