import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ecogrid_intelligence/domain/repositories/power_plant_repository.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PowerPlantRepository powerPlantRepository;
  final LGRepository lgRepository;

  HomeBloc({
    required this.powerPlantRepository,
    required this.lgRepository,
  }) : super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final plantsResult = await powerPlantRepository.getAllPlants();

    plantsResult.fold(
      (failure) => emit(HomeError(failure.message)),
      (plants) => emit(HomeLoaded(
        totalPlants: plants.length,
        lgStatus: lgRepository.connectionStatus,
      )),
    );
  }
}
