import 'package:equatable/equatable.dart';
import '../../../domain/model/region.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

class HomeRegionSelected extends HomeEvent {
  final Region region;
  const HomeRegionSelected(this.region);
  @override
  List<Object?> get props => [region];
}

class HomeGlobalOverviewTapped extends HomeEvent {
  const HomeGlobalOverviewTapped();
}

class HomeSearchSubmitted extends HomeEvent {
  final String query;
  const HomeSearchSubmitted(this.query);
  @override
  List<Object?> get props => [query];
}
