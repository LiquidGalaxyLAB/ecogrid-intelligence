import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

/// Load initial data (plant count, LG status).
class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

/// User selected a quick region chip.
class HomeRegionSelected extends HomeEvent {
  final Region region;
  const HomeRegionSelected(this.region);
  @override
  List<Object?> get props => [region];
}

/// User tapped "View Global Overview".
class HomeGlobalOverviewTapped extends HomeEvent {
  const HomeGlobalOverviewTapped();
}

/// User submitted a search query.
class HomeSearchSubmitted extends HomeEvent {
  final String query;
  const HomeSearchSubmitted(this.query);
  @override
  List<Object?> get props => [query];
}
