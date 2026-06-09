import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_constants.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = ApiClient.createDio(baseUrl: ApiConstants.groqBaseUrl);

  // Generic GET
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _dio.get(
      endpoint,
      queryParameters: queryParams,
      options: Options(headers: headers),
    );
  }

  // Generic POST
  Future<Response> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return await _dio.post(
      endpoint,
      data: body,
      options: Options(headers: headers),
    );
  }
}
