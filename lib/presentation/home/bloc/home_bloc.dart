import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ecogrid_intelligence/domain/repository/power_plant_repository.dart';
import 'package:ecogrid_intelligence/service/lg_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PowerPlantRepository powerPlantRepository;
  final LGService lgService;

  HomeBloc({required this.powerPlantRepository, required this.lgService})
    : super(const HomeInitial()) {
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
      (plants) => emit(
        HomeLoaded(
          totalPlants: plants.length,
          lgStatus: lgService.connectionStatus,
        ),
      ),
    );
  }
}
