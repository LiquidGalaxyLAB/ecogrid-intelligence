import 'package:equatable/equatable.dart';
import '../../../domain/model/power_plant.dart';
import '../../../domain/model/region.dart';
import '../../../core/enums/plant_type.dart';
import '../../../core/enums/risk_level.dart';
import '../../../core/enums/stress_filter.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();
  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  final Region? region;
  final List<PowerPlant> plants;
  final List<PowerPlant> filteredPlants;
  final PlantType? activeTypeFilter;
  final StressFilter? activeStressFilter;
  final RiskLevel? activeRiskFilter;
  final int totalFilteredCount;
  final String? aiInsight;
  final bool isLoadingInsight;
  final int displayLimit;
  final String searchQuery;
  final bool isScanning;
  final double scanProgress;

  const ExploreLoaded({
    this.region,
    required this.plants,
    required this.filteredPlants,
    this.activeTypeFilter,
    this.activeStressFilter,
    this.activeRiskFilter,
    this.totalFilteredCount = 0,
    this.aiInsight,
    this.isLoadingInsight = false,
    this.displayLimit = 50,
    this.searchQuery = '',
    this.isScanning = false,
    this.scanProgress = 0.0,
  });

  @override
  List<Object?> get props => [
    region,
    plants,
    filteredPlants,
    activeTypeFilter,
    activeStressFilter,
    activeRiskFilter,
    totalFilteredCount,
    aiInsight,
    isLoadingInsight,
    displayLimit,
    searchQuery,
    isScanning,
    scanProgress,
  ];

  ExploreLoaded copyWith({
    Region? region,
    List<PowerPlant>? plants,
    List<PowerPlant>? filteredPlants,
    Object? activeTypeFilter = const Object(),
    Object? activeStressFilter = const Object(),
    Object? activeRiskFilter = const Object(),
    int? totalFilteredCount,
    String? aiInsight,
    bool? isLoadingInsight,
    int? displayLimit,
    String? searchQuery,
    bool? isScanning,
    double? scanProgress,
    bool clearAiInsight = false,
  }) {
    return ExploreLoaded(
      region: region ?? this.region,
      plants: plants ?? this.plants,
      filteredPlants: filteredPlants ?? this.filteredPlants,
      activeTypeFilter: activeTypeFilter == const Object()
          ? this.activeTypeFilter
          : activeTypeFilter as PlantType?,
      activeStressFilter: activeStressFilter == const Object()
          ? this.activeStressFilter
          : activeStressFilter as StressFilter?,
      activeRiskFilter: activeRiskFilter == const Object()
          ? this.activeRiskFilter
          : activeRiskFilter as RiskLevel?,
      totalFilteredCount: totalFilteredCount ?? this.totalFilteredCount,
      aiInsight: clearAiInsight ? null : (aiInsight ?? this.aiInsight),
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
      displayLimit: displayLimit ?? this.displayLimit,
      searchQuery: searchQuery ?? this.searchQuery,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
    );
  }
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);
  @override
  List<Object?> get props => [message];
}
