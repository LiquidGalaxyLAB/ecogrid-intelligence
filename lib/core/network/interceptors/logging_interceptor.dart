import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Interceptor that logs all outgoing requests and incoming responses at a
/// structured level using the [Logger] package.
///
/// Logging is suppressed automatically in release builds via [kDebugMode].
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        '➡️  [${options.method}] ${options.uri}\n'
        'Headers: ${_sanitizeHeaders(options.headers)}\n'
        'Query: ${options.queryParameters}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        '✅ [${response.statusCode}] ${response.requestOptions.uri}\n'
        'Duration: ${_elapsed(response.requestOptions)} ms',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e(
        '❌ [${err.response?.statusCode}] ${err.requestOptions.uri}\n'
        'Type: ${err.type}\n'
        'Message: ${err.message}',
      );
    }
    handler.next(err);
  }

  /// Masks the Authorization header value so keys never appear in plain-text
  /// logs.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = '***';
    }
    return sanitized;
  }

  /// Returns elapsed milliseconds since the request was created. Dio doesn't
  /// expose a native duration, so we derive it from DateTime.now().
  int _elapsed(RequestOptions options) {
    final extra = options.extra['_requestStart'];
    if (extra is DateTime) {
      return DateTime.now().difference(extra).inMilliseconds;
    }
    return -1;
  }
}
