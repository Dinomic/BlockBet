import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Supplies the stored JWT so the client stays decoupled from any feature.
typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({required TokenProvider tokenProvider, Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Auth endpoints are public; every other call carries the JWT.
        if (!options.path.startsWith('/auth/')) {
          final token = await tokenProvider();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));
  }

  final Dio dio;
}
