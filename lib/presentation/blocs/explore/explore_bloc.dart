import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/domain/repositories/power_plant_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/climate_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/ai_repository.dart';
import 'explore_event.dart';
import 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final PowerPlantRepository powerPlantRepository;
  final ClimateRepository climateRepository;
  final LGRepository lgRepository;
  final AIRepository aiRepository;

  ExploreBloc({
    required this.powerPlantRepository,
    required this.climateRepository,
    required this.lgRepository,
    required this.aiRepository,
  }) : super(const ExploreInitial()) {
    on<ExploreRegionLoaded>(_onRegionLoaded);
    on<ExploreFilterChanged>(_onFilterChanged);
    on<ExploreGlobalLoaded>(_onGlobalLoaded);
  }

  Future<void> _onRegionLoaded(
    ExploreRegionLoaded event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreLoading());

    // Send FlyTo to LG immediately
    await lgRepository.flyTo(
      event.region.centerLat,
      event.region.centerLon,
      0,
      0,
      60,
      event.region.defaultZoom * 100000,
    );

    // Get plants in region
    final plantsResult =
        await powerPlantRepository.getPlantsByRegion(event.region);

    await plantsResult.fold(
      (failure) async => emit(ExploreError(failure.message)),
      (plants) async {
        emit(ExploreLoaded(
          region: event.region,
          plants: plants,
          filteredPlants: plants,
          isLoadingInsight: true,
        ));

        // Generate AI insight in background
        final typeDistribution = <String, int>{};
        for (final p in plants) {
          typeDistribution[p.primaryFuel.displayName] =
              (typeDistribution[p.primaryFuel.displayName] ?? 0) + 1;
        }

        final insightResult = await aiRepository.generateRegionalInsight(
          regionName: event.region.displayName ?? event.region.name,
          totalPlants: plants.length,
          highRiskPlants: (plants.length * 0.15).round(),
          plantTypeDistribution: typeDistribution,
        );

        insightResult.fold(
          (_) => null,
          (insight) {
            if (state is ExploreLoaded) {
              emit((state as ExploreLoaded).copyWith(
                aiInsight: insight,
                isLoadingInsight: false,
              ));
            }
          },
        );
      },
    );
  }

  Future<void> _onGlobalLoaded(
    ExploreGlobalLoaded event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreLoading());

    final plantsResult = await powerPlantRepository.getAllPlants();

    plantsResult.fold(
      (failure) => emit(ExploreError(failure.message)),
      (plants) => emit(ExploreLoaded(
        plants: plants,
        filteredPlants: plants.take(100).toList(),
      )),
    );
  }

  void _onFilterChanged(
    ExploreFilterChanged event,
    Emitter<ExploreState> emit,
  ) {
    if (state is! ExploreLoaded) return;
    final currentState = state as ExploreLoaded;

    final typeFilters =
        event.typeFilters ?? currentState.activeTypeFilters;
    final riskFilters =
        event.riskFilters ?? currentState.activeRiskFilters;

    var filtered = currentState.plants;
    if (typeFilters.isNotEmpty) {
      filtered = filtered
          .where((p) => typeFilters.contains(p.primaryFuel))
          .toList();
    }

    emit(currentState.copyWith(
      filteredPlants: filtered,
      activeTypeFilters: typeFilters,
      activeRiskFilters: riskFilters,
    ));
  }
}
