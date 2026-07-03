import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/resources/data_state.dart';
import '../../../core/resources/app_state.dart';
import '../../../domain/model/region.dart';
import '../../../domain/model/power_plant.dart';
import '../../../domain/usecases/plant/services/search_plants_usecase.dart';
import '../../../domain/usecases/plant/services/search_regions_usecase.dart';

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

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchPlantsUsecase searchPlantsUsecase;
  final SearchRegionsUsecase searchRegionsUsecase;
  Timer? _debounceTimer;
  SearchBloc({
    required this.searchPlantsUsecase,
    required this.searchRegionsUsecase,
  }) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<_SearchTriggered>(_onSearchTriggered);
    on<SearchCleared>(_onCleared);
  }
  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    final bool willSearch = event.query.trim().isNotEmpty;
    emit(state.copyWith(query: event.query, isSearching: willSearch));
    _debounceTimer?.cancel();
    if (willSearch) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        add(_SearchTriggered(event.query));
      });
    } else {
      emit(state.copyWith(results: [], isSearching: false));
    }
  }

  Future<void> _onSearchTriggered(
    _SearchTriggered event,
    Emitter<SearchState> emit,
  ) async {
    if (state.query != event.query) return;
    final results = await Future.wait([
      searchPlantsUsecase(params: event.query).last,
      searchRegionsUsecase(params: event.query).last,
    ]);
    final plantResult = results[0] as DataState<List<PowerPlant>>;
    final regionResult = results[1] as DataState<List<Region>>;
    if (state.query == event.query) {
      final plants = plantResult is DataSuccess<List<PowerPlant>>
          ? AppSuccess(plantResult.data!).data!
          : <PowerPlant>[];
      final regions = regionResult is DataSuccess<List<Region>>
          ? AppSuccess(regionResult.data!).data!
          : <Region>[];
      emit(
        state.copyWith(
          results: plants,
          regionResults: regions,
          isSearching: false,
        ),
      );
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
