import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:ecogrid_intelligence/domain/model/region.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/repository/power_plant_repository.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

// States
class SearchState extends Equatable {
  final String query;
  final List<PowerPlant> results;
  final List<Region> regionResults;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.regionResults = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<PowerPlant>? results,
    List<Region>? regionResults,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      regionResults: regionResults ?? this.regionResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [query, results, regionResults, isSearching];
}

class _SearchTriggered extends SearchEvent {
  final String query;
  const _SearchTriggered(this.query);
  @override
  List<Object?> get props => [query];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PowerPlantRepository powerPlantRepository;
  Timer? _debounceTimer;

  SearchBloc({required this.powerPlantRepository})
      : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<_SearchTriggered>(_onSearchTriggered);
    on<SearchCleared>(_onCleared);
  }

  void _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) {
    // 1. Immediately update UI to show loading state if we have a query
    final bool willSearch = event.query.trim().isNotEmpty;
    emit(state.copyWith(query: event.query, isSearching: willSearch));

    // 2. Clear any existing timer
    _debounceTimer?.cancel();

    // 3. Start a new timer that dispatches the internal search event
    if (willSearch) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        add(_SearchTriggered(event.query));
      });
    } else {
      // If query is empty, immediately clear results
      emit(state.copyWith(results: [], isSearching: false));
    }
  }

  Future<void> _onSearchTriggered(
    _SearchTriggered event,
    Emitter<SearchState> emit,
  ) async {
    // If the state query has changed since this event was queued (rare but possible), ignore
    if (state.query != event.query) return;

    // Fetch both plants and regions concurrently
    final plantFuture = powerPlantRepository.searchPlants(event.query);
    final regionFuture = powerPlantRepository.searchRegions(event.query);

    final results = await Future.wait([plantFuture, regionFuture]);
    final plantResult = results[0] as dartz.Either<dynamic, List<PowerPlant>>;
    final regionResult = results[1] as dartz.Either<dynamic, List<Region>>;
    
    // Only emit if the state query is still the same as the one we just searched for
    if (state.query == event.query) {
      final plants = plantResult.fold((_) => <PowerPlant>[], (p) => p);
      final regions = regionResult.fold((_) => <Region>[], (r) => r);
      
      emit(state.copyWith(
        results: plants,
        regionResults: regions,
        isSearching: false,
      ));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    emit(const SearchState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
