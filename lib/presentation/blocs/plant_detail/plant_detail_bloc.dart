import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/entities/climate_data.dart';
import 'package:ecogrid_intelligence/domain/entities/cvs_result.dart';
import 'package:ecogrid_intelligence/domain/repositories/climate_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/ai_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';
import 'package:ecogrid_intelligence/core/utils/cvs_calculator.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

// Events
abstract class PlantDetailEvent extends Equatable {
  const PlantDetailEvent();
  @override
  List<Object?> get props => [];
}

class PlantDetailLoadRequested extends PlantDetailEvent {
  final PowerPlant plant;
  const PlantDetailLoadRequested(this.plant);
  @override
  List<Object?> get props => [plant];
}

class PlantDetailScenarioSimulated extends PlantDetailEvent {
  final double tempMultiplier;
  final double waterMultiplier;
  final double windMultiplier;
  final String scenarioType;
  const PlantDetailScenarioSimulated({
    this.tempMultiplier = 1.0,
    this.waterMultiplier = 1.0,
    this.windMultiplier = 1.0,
    this.scenarioType = 'Custom',
  });
  @override
  List<Object?> get props =>
      [tempMultiplier, waterMultiplier, windMultiplier, scenarioType];
}

// States
abstract class PlantDetailState extends Equatable {
  const PlantDetailState();
  @override
  List<Object?> get props => [];
}

class PlantDetailInitial extends PlantDetailState {
  const PlantDetailInitial();
}

class PlantDetailLoading extends PlantDetailState {
  const PlantDetailLoading();
}

class PlantDetailLoaded extends PlantDetailState {
  final PowerPlant plant;
  final ClimateData? climateData;
  final CVSResult? cvsResult;
  final String? aiInsight;
  final List<ClimateData> historicalData;
  final double? projectedCvs;
  final String? scenarioInsight;
  final bool isLoadingInsight;

  const PlantDetailLoaded({
    required this.plant,
    this.climateData,
    this.cvsResult,
    this.aiInsight,
    this.historicalData = const [],
    this.projectedCvs,
    this.scenarioInsight,
    this.isLoadingInsight = false,
  });

  @override
  List<Object?> get props => [
        plant,
        climateData,
        cvsResult,
        aiInsight,
        historicalData,
        projectedCvs,
        scenarioInsight,
        isLoadingInsight,
      ];

  PlantDetailLoaded copyWith({
    PowerPlant? plant,
    ClimateData? climateData,
    CVSResult? cvsResult,
    String? aiInsight,
    List<ClimateData>? historicalData,
    double? projectedCvs,
    String? scenarioInsight,
    bool? isLoadingInsight,
  }) {
    return PlantDetailLoaded(
      plant: plant ?? this.plant,
      climateData: climateData ?? this.climateData,
      cvsResult: cvsResult ?? this.cvsResult,
      aiInsight: aiInsight ?? this.aiInsight,
      historicalData: historicalData ?? this.historicalData,
      projectedCvs: projectedCvs ?? this.projectedCvs,
      scenarioInsight: scenarioInsight ?? this.scenarioInsight,
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
    );
  }
}

class PlantDetailError extends PlantDetailState {
  final String message;
  const PlantDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PlantDetailBloc extends Bloc<PlantDetailEvent, PlantDetailState> {
  final ClimateRepository climateRepository;
  final AIRepository aiRepository;
  final LGRepository lgRepository;

  PlantDetailBloc({
    required this.climateRepository,
    required this.aiRepository,
    required this.lgRepository,
  }) : super(const PlantDetailInitial()) {
    on<PlantDetailLoadRequested>(_onLoadRequested);
    on<PlantDetailScenarioSimulated>(_onScenarioSimulated);
  }

  Future<void> _onLoadRequested(
    PlantDetailLoadRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    emit(const PlantDetailLoading());

    final plant = event.plant;

    // FlyTo plant location on LG
    await lgRepository.flyTo(
      plant.latitude, plant.longitude, 0, 0, 60, 15000,
    );

    // Get climate data
    final climateResult = await climateRepository.getCurrentClimate(
      plant.latitude, plant.longitude,
    );

    ClimateData? climateData;
    CVSResult? cvsResult;

    climateResult.fold(
      (_) => null,
      (data) {
        climateData = data;
        final score = CVSCalculator.computeCVS(
          plantType: plant.primaryFuel,
          tempAnomaly: data.tempAnomaly,
          waterAnomaly: data.waterAnomaly,
          windAnomaly: data.windAnomaly,
        );
        final stresses = CVSCalculator.computeStressBreakdown(
          plantType: plant.primaryFuel,
          tempAnomaly: data.tempAnomaly,
          waterAnomaly: data.waterAnomaly,
          windAnomaly: data.windAnomaly,
        );
        cvsResult = CVSResult(
          plantId: plant.id,
          score: score,
          riskLevel: RiskLevel.fromScore(score),
          temperatureStress: stresses['temperature'] ?? 0,
          waterStress: stresses['water'] ?? 0,
          windStress: stresses['wind'] ?? 0,
          computedAt: DateTime.now(),
        );
      },
    );

    emit(PlantDetailLoaded(
      plant: plant,
      climateData: climateData,
      cvsResult: cvsResult,
      isLoadingInsight: true,
    ));

    // Load historical data
    final now = DateTime.now();
    final historicalResult = await climateRepository.getHistoricalClimate(
      plant.latitude, plant.longitude,
      startDate: now.subtract(const Duration(days: 365)),
      endDate: now.subtract(const Duration(days: 1)),
    );

    List<ClimateData> historicalData = [];
    historicalResult.fold(
      (_) => null,
      (data) => historicalData = data,
    );

    // Generate AI insight
    String? aiInsight;
    if (cvsResult != null) {
      final insightResult = await aiRepository.generatePlantInsight(
        plantName: plant.name,
        plantType: plant.primaryFuel.displayName,
        cvsScore: cvsResult!.score,
        tempStress: cvsResult!.temperatureStress,
        waterStress: cvsResult!.waterStress,
        windStress: cvsResult!.windStress,
        country: plant.countryLong ?? plant.country,
      );
      insightResult.fold((_) => null, (insight) => aiInsight = insight);
    }

    if (state is PlantDetailLoaded) {
      emit((state as PlantDetailLoaded).copyWith(
        historicalData: historicalData,
        aiInsight: aiInsight,
        isLoadingInsight: false,
      ));
    }
  }

  Future<void> _onScenarioSimulated(
    PlantDetailScenarioSimulated event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;
    final climate = currentState.climateData;
    final plant = currentState.plant;
    if (climate == null) return;

    final projected = CVSCalculator.simulateScenario(
      plantType: plant.primaryFuel,
      tempAnomaly: climate.tempAnomaly,
      waterAnomaly: climate.waterAnomaly,
      windAnomaly: climate.windAnomaly,
      tempMultiplier: event.tempMultiplier,
      waterMultiplier: event.waterMultiplier,
      windMultiplier: event.windMultiplier,
    );

    emit(currentState.copyWith(
      projectedCvs: projected,
      isLoadingInsight: true,
    ));

    // Generate scenario insight
    final insightResult = await aiRepository.generateScenarioAnalysis(
      plantName: plant.name,
      plantType: plant.primaryFuel.displayName,
      currentCvs: currentState.cvsResult?.score ?? 0,
      projectedCvs: projected,
      scenarioType: event.scenarioType,
    );

    insightResult.fold(
      (_) => null,
      (insight) {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            scenarioInsight: insight,
            isLoadingInsight: false,
          ));
        }
      },
    );
  }
}
