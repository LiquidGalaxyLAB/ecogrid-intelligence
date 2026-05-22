import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

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
  final Set<PlantType>? typeFilters;
  final Set<RiskLevel>? riskFilters;
  const ExploreFilterChanged({this.typeFilters, this.riskFilters});
  @override
  List<Object?> get props => [typeFilters, riskFilters];
}

class ExplorePlantSelected extends ExploreEvent {
  final PowerPlant plant;
  const ExplorePlantSelected(this.plant);
  @override
  List<Object?> get props => [plant];
}

class ExploreSearchInRegion extends ExploreEvent {
  final String query;
  const ExploreSearchInRegion(this.query);
  @override
  List<Object?> get props => [query];
}
