import 'package:dio/dio.dart';
import '../exception/invalid_response_exception.dart';
import '../resources/network_state.dart';

/// Centralised handler that converts raw [DioException] (and generic [Exception])
/// values into strongly-typed [NetworkFailure] objects so every data source
/// can delegate error handling here instead of duplicating switch logic.
class NetworkExceptionHandler {
  const NetworkExceptionHandler._();

  /// Wraps a [DioException] in a [NetworkFailure] with a human-readable
  /// message and the original HTTP status code (when available).
  static NetworkFailure<T> fromDioException<T>(DioException e) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;

    final Exception exception = switch (e.type) {
      DioExceptionType.connectionTimeout => const ConnectionException(
          message: 'Connection timed out. Please check your network.',
        ),
      DioExceptionType.sendTimeout => const ConnectionException(
          message: 'Request timed out while sending data.',
        ),
      DioExceptionType.receiveTimeout => const ConnectionException(
          message: 'Server took too long to respond.',
        ),
      DioExceptionType.badResponse => ServerException(
          message: 'Server returned an unexpected response: $body',
          statusCode: statusCode,
        ),
      DioExceptionType.cancel => const ConnectionException(
          message: 'Request was cancelled.',
        ),
      DioExceptionType.connectionError => const ConnectionException(
          message:
              'Could not reach the server. Please check your connection.',
        ),
      _ => ServerException(
          message: e.message ?? 'An unknown network error occurred.',
          statusCode: statusCode,
        ),
    };

    return NetworkFailure<T>(exception: exception, statusCode: statusCode);
  }

  /// Wraps any generic [Exception] in a [NetworkFailure].
  static NetworkFailure<T> fromException<T>(Exception e) {
    return NetworkFailure<T>(exception: e);
  }

  /// Wraps an unknown [Object] (e.g. from a bare `catch (e)` clause) in a
  /// [NetworkFailure].
  static NetworkFailure<T> fromObject<T>(Object e) {
    return NetworkFailure<T>(
      exception: Exception('Unexpected error: $e'),
    );
  }
}
