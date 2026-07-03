class InvalidResponseException implements Exception {
  final String message;
  final String? response;
  const InvalidResponseException({
    required this.message,
    required this.response,
  });
  @override
  String toString() => message;
}

class ParseException implements Exception {
  final String message;
  const ParseException({required this.message});
  @override
  String toString() => 'ParseException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException({required this.message});
  @override
  String toString() => 'ConnectionException: $message';
}
