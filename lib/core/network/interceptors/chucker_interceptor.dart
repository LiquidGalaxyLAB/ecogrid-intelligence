import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';

/// Interceptor that integrates Chucker for in-app HTTP request inspection.
///
/// Chucker records all requests and responses and surfaces them via a
/// notification panel, making debugging network traffic effortless without
/// needing a desktop proxy.
class ChuckerInterceptor extends Interceptor {
  final ChuckerDioInterceptor _delegate;

  ChuckerInterceptor() : _delegate = ChuckerDioInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _delegate.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _delegate.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _delegate.onError(err, handler);
  }
}
