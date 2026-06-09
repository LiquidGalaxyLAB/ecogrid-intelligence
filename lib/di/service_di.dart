import 'package:get_it/get_it.dart';
import 'package:ecogrid_intelligence/service/ssh_service.dart';
import 'package:ecogrid_intelligence/service/tts_service.dart';
import 'package:ecogrid_intelligence/service/lg_service.dart';

final sl = GetIt.instance;

void initServices() {
  sl.registerLazySingleton(() => SSHService());
  sl.registerLazySingleton(() => TTSService());
  sl.registerLazySingleton<LGService>(
    () => LGService(remoteDataSource: sl(), settingsDataSource: sl()),
  );
}
