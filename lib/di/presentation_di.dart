import 'package:get_it/get_it.dart';
import 'package:ecogrid_intelligence/presentation/home/bloc/home_bloc.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_bloc.dart';
import 'package:ecogrid_intelligence/presentation/plant_detail/bloc/plant_detail_bloc.dart';
import 'package:ecogrid_intelligence/presentation/lg_connection/bloc/lg_connection_bloc.dart';
import 'package:ecogrid_intelligence/presentation/home/bloc/search_bloc.dart';

final sl = GetIt.instance;

void initPresentation() {
  sl.registerFactory(
    () => HomeBloc(powerPlantRepository: sl(), lgService: sl()),
  );
  sl.registerFactory(
    () => ExploreBloc(
      powerPlantRepository: sl(),
      cvsRepository: sl(),
      lgService: sl(),
      aiRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => PlantDetailBloc(
      cvsRepository: sl(),
      aiRepository: sl(),
      lgService: sl(),
      climateRepository: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => LGConnectionBloc(lgService: sl(), sshService: sl()),
  );
  sl.registerFactory(() => SearchBloc(powerPlantRepository: sl()));
}
