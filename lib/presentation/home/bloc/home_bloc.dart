import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/resources/data_state.dart';
import '../../../service/lg_service.dart';
import '../../../domain/usecases/plant/bloc/init_plant_bloc_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final LGService lgService;
  final InitPlantBlocUseCase initPlantBlocUseCase;

  HomeBloc({
    required this.lgService,
    required this.initPlantBlocUseCase,
  }) : super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final plantsResult = await initPlantBlocUseCase();

    if (plantsResult is DataSuccess) {
      emit(HomeLoaded(
        totalPlants: plantsResult.data!.length,
        lgStatus: lgService.connectionStatus,
      ));
    } else {
      emit(HomeError(plantsResult.exception?.toString() ?? 'Failed to load plants'));
    }
  }
}
