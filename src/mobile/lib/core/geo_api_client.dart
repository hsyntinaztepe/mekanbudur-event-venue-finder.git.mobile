import 'package:dio/dio.dart';

/// Simple HTTP client dedicated to the Geo microservice.
class GeoApiClient {
  static const String baseUrl = 'http://10.0.2.2:8082/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Dio get dio => _dio;
}
