import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';

/// Interceptor that automatically injects the Authorization header for
/// endpoints that require a Bearer token (e.g., Gemini API).
///
/// Requests that already carry an [Authorization] header (e.g., set
/// per-request) are left unchanged so that per-call overrides still work.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = ApiConstants.geminiApiKey;

    // Only inject if a key is available and the request doesn't already have
    // its own Authorization header.
    if (apiKey.isNotEmpty &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $apiKey';
    }

    handler.next(options);
  }
}
