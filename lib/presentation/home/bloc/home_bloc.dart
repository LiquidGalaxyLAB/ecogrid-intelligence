import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/resources/app_state.dart';
import '../../../core/resources/data_state.dart';
import '../../../domain/model/power_plant.dart';
import '../../../domain/usecases/plant/bloc/init_plant_bloc_usecase.dart';
import 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, AppState<List<PowerPlant>>> {
  final InitPlantBlocUseCase initPlantBlocUseCase;
  HomeBloc({required this.initPlantBlocUseCase}) : super(const AppLoading()) {
    on<HomeLoadRequested>(_onLoadRequested);
  }
  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<AppState<List<PowerPlant>>> emit,
  ) async {
    await emit.forEach<DataState<List<PowerPlant>>>(
      initPlantBlocUseCase(),
      onData: (dataState) {
        if (dataState is DataLoading<List<PowerPlant>>) {
          return const AppLoading<List<PowerPlant>>();
        } else if (dataState is DataEmpty<List<PowerPlant>>) {
          return const AppEmpty<List<PowerPlant>>();
        } else if (dataState is DataSuccess<List<PowerPlant>>) {
          return AppSuccess<List<PowerPlant>>(dataState.data!);
        } else {
          return AppFailure<List<PowerPlant>>(
            dataState.exception ?? Exception('Failed to load plants'),
          );
        }
      },
      onError: (error, _) => AppFailure<List<PowerPlant>>(Exception(error)),
    );
  }
}
