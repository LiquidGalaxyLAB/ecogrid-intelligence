import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static final Alice _alice = Alice(
    configuration: AliceConfiguration(
      showNotification: true,
      showInspectorOnShake: true,
    ),
  );

  static Alice get alice => _alice;

  static Dio createDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // attach Alice interceptor — captures all requests/responses
    final aliceDioAdapter = AliceDioAdapter();
    _alice.addAdapter(aliceDioAdapter);
    dio.interceptors.add(aliceDioAdapter);

    return dio;
  }
}
