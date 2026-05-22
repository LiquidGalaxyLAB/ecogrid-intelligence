// Core exceptions thrown by data sources.

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException({required this.message});

  @override
  String toString() => 'ConnectionException: $message';
}

class ParseException implements Exception {
  final String message;
  const ParseException({required this.message});

  @override
  String toString() => 'ParseException: $message';
}
