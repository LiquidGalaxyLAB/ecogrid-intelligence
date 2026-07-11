import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/remote/api_services/gemini_api_service.dart';
import '../data/remote/api_services/open_meteo_api_service.dart';
import '../data/remote/data_sources/ai_data_source.dart';
import '../data/remote/data_sources/gemini_remote_ds.dart';
import '../data/remote/data_sources/open_meteo_remote_ds.dart';
import 'dependency_injection.dart';

void registerNetworkDependencies() {
  final dio = ApiClient.createDio();
  dio.options.connectTimeout = ApiConstants.apiTimeout;
  dio.options.receiveTimeout = ApiConstants.apiTimeout;
  sl.registerLazySingleton(() => dio);
  sl.registerLazySingleton<GeminiApiService>(
    () => GeminiRestApiService(dio: sl()),
  );
  sl.registerLazySingleton(() => OpenMeteoApiService(dio: sl()));
  sl.registerLazySingleton(() => OpenMeteoRemoteDataSource(apiService: sl()));
  sl.registerLazySingleton<AIDataSource>(
    () => GeminiRemoteDataSource(apiService: sl()),
  );
}
