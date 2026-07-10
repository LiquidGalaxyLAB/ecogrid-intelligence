import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/chucker_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Factory that creates pre-configured [Dio] instances for the application.
///
/// Every instance produced here automatically includes:
///   • [ChuckerInterceptor]  – in-app HTTP inspector
///   • [LoggingInterceptor]  – structured console logging (debug builds only)
///   • [AuthInterceptor]     – Bearer-token injection
class ApiClient {
  ApiClient._();

  /// The [NavigatorKey] that Chucker requires to display its overlay.
  ///
  /// Register this key on your [MaterialApp] so Chucker can open its
  /// inspector screen from anywhere in the widget tree.
  static GlobalKey<NavigatorState> get navigatorKey =>
      ChuckerFlutter.navigatorKey;

  /// Creates and returns a fully-configured [Dio] instance.
  ///
  /// [baseUrl] is optional — leave it empty when the data source constructs
  /// full URLs itself (e.g. Open-Meteo, Gemini).
  static Dio createDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors are executed in the order they are added.
    // 1. Logging   – fires first so we always see the raw request.
    // 2. Auth      – injects credentials before the request leaves.
    // 3. Chucker   – captures the final request + response for inspection.
    dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(),
      ChuckerInterceptor(),
    ]);

    return dio;
  }
}
