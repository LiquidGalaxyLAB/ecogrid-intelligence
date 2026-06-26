import 'package:get_it/get_it.dart';
import '../service/ssh_service.dart';
import '../service/tts_service.dart';
import '../service/lg_service.dart';
import '../service/speech_to_text_service.dart';

final sl = GetIt.instance;

void initServices() {
  sl.registerLazySingleton(() => SSHService());
  sl.registerLazySingleton(() => TTSService());
  sl.registerLazySingleton(() => SpeechToTextService());
  sl.registerLazySingleton<LGService>(
    () => LGService(remoteDataSource: sl(), settingsDataSource: sl()),
  );
}
