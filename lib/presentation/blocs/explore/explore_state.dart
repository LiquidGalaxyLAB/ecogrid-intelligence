import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

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
  final Set<PlantType> activeTypeFilters;
  final Set<RiskLevel> activeRiskFilters;
  final String? aiInsight;
  final bool isLoadingInsight;

  const ExploreLoaded({
    this.region,
    required this.plants,
    required this.filteredPlants,
    this.activeTypeFilters = const {},
    this.activeRiskFilters = const {},
    this.aiInsight,
    this.isLoadingInsight = false,
  });

  @override
  List<Object?> get props => [
        region,
        plants,
        filteredPlants,
        activeTypeFilters,
        activeRiskFilters,
        aiInsight,
        isLoadingInsight,
      ];

  ExploreLoaded copyWith({
    Region? region,
    List<PowerPlant>? plants,
    List<PowerPlant>? filteredPlants,
    Set<PlantType>? activeTypeFilters,
    Set<RiskLevel>? activeRiskFilters,
    String? aiInsight,
    bool? isLoadingInsight,
  }) {
    return ExploreLoaded(
      region: region ?? this.region,
      plants: plants ?? this.plants,
      filteredPlants: filteredPlants ?? this.filteredPlants,
      activeTypeFilters: activeTypeFilters ?? this.activeTypeFilters,
      activeRiskFilters: activeRiskFilters ?? this.activeRiskFilters,
      aiInsight: aiInsight ?? this.aiInsight,
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
    );
  }
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);
  @override
  List<Object?> get props => [message];
}
