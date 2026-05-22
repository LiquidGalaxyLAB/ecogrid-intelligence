import 'package:equatable/equatable.dart';

/// Base failure class for error handling via Either<Failure, T>.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/API failure (Open-Meteo, Gemini).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Local cache/storage failure.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// SSH/LG connection failure.
class ConnectionFailure extends Failure {
  const ConnectionFailure({required super.message, super.code});
}

/// Data parsing failure (CSV, JSON).
class ParseFailure extends Failure {
  const ParseFailure({required super.message, super.code});
}

/// Network connectivity failure.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code,
  });
}

/// Unknown/unexpected failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code,
  });
}
