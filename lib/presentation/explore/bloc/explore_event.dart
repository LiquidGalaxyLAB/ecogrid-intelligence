import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';
import 'package:ecogrid_intelligence/core/enums/stress_filter.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();
  @override
  List<Object?> get props => [];
}

class ExploreRegionLoaded extends ExploreEvent {
  final Region region;
  const ExploreRegionLoaded(this.region);
  @override
  List<Object?> get props => [region];
}

class ExploreGlobalLoaded extends ExploreEvent {
  const ExploreGlobalLoaded();
}

class ExploreFilterChanged extends ExploreEvent {
  final PlantType? typeFilter;
  final StressFilter? stressFilter;
  final bool clearTypeFilter;
  final bool clearStressFilter;

  const ExploreFilterChanged({
    this.typeFilter,
    this.stressFilter,
    this.clearTypeFilter = false,
    this.clearStressFilter = false,
  });

  @override
  List<Object?> get props => [
    typeFilter,
    stressFilter,
    clearTypeFilter,
    clearStressFilter,
  ];
}

class ExplorePlantSelected extends ExploreEvent {
  final PowerPlant plant;
  const ExplorePlantSelected(this.plant);
  @override
  List<Object?> get props => [plant];
}

class ExploreSearchQueryChanged extends ExploreEvent {
  final String query;
  const ExploreSearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ExploreLoadMore extends ExploreEvent {
  const ExploreLoadMore();
}

class ExploreRiskFilterChanged extends ExploreEvent {
  final RiskLevel? riskLevel;
  const ExploreRiskFilterChanged({this.riskLevel});
  @override
  List<Object?> get props => [riskLevel];
}

/// User explicitly tapped "Analyse Regional Risk" button.
class ExploreGenerateRegionalInsight extends ExploreEvent {
  const ExploreGenerateRegionalInsight();
}

/// User explicitly tapped "Show Plants on LG" button.
class ExploreShowPlantsOnLG extends ExploreEvent {
  const ExploreShowPlantsOnLG();
}

/// Dispatched when the user navigates back from plant detail to the explore screen.
/// Triggers the ExploreBloc to re-send the region LG overlay.
class ExploreLGRestoreRequested extends ExploreEvent {
  const ExploreLGRestoreRequested();
}
