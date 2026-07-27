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

    // Native Gemini API uses ?key= query param, not Bearer token.
    final isNativeGemini =
        options.uri.host.contains('generativelanguage.googleapis.com') &&
        !options.path.contains('/openai/');

    // Only inject if a key is available, the request doesn't already have
    // its own Authorization header, and it's not a native Gemini call.
    if (apiKey.isNotEmpty &&
        !isNativeGemini &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $apiKey';
    }

    handler.next(options);
  }
}
