import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/repositories/power_plant_repository.dart';

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
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<PowerPlant>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [query, results, isSearching];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PowerPlantRepository powerPlantRepository;
  Timer? _debounceTimer;

  SearchBloc({required this.powerPlantRepository})
      : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCleared>(_onCleared);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(query: event.query, isSearching: true));

    // Debounce
    _debounceTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));

    if (event.query.trim().isEmpty) {
      emit(state.copyWith(results: [], isSearching: false));
      return;
    }

    final result = await powerPlantRepository.searchPlants(event.query);
    result.fold(
      (_) => emit(state.copyWith(isSearching: false)),
      (plants) => emit(state.copyWith(results: plants, isSearching: false)),
    );
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
