import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Supplies the stored access token so the client stays decoupled from any feature.
typedef TokenProvider = Future<String?> Function();

/// Persists a freshly rotated token pair.
typedef TokensSaver = Future<void> Function(String accessToken, String refreshToken);

class ApiClient {
  ApiClient({
    required TokenProvider tokenProvider,
    this.refreshTokenProvider,
    this.onTokensRefreshed,
    this.onSessionExpired,
    Dio? dio,
  }) : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Auth endpoints are public; every other call carries the access token.
        if (!options.path.startsWith('/auth/')) {
          final token = await tokenProvider();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final canRefresh = refreshTokenProvider != null && onTokensRefreshed != null;
        if (!canRefresh ||
            error.response?.statusCode != 401 ||
            request.path.startsWith('/auth/') ||
            request.extra[_retriedKey] == true) {
          return handler.next(error);
        }

        // Access token expired: rotate the refresh token once and replay the request.
        final newAccessToken = await _refresh();
        if (newAccessToken == null) return handler.next(error);

        request.headers['Authorization'] = 'Bearer $newAccessToken';
        request.extra[_retriedKey] = true;
        try {
          handler.resolve(await this.dio.fetch<dynamic>(request));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ));
  }

  static const _retriedKey = 'auth_retried';

  final Dio dio;

  /// Reads the stored refresh token.
  final TokenProvider? refreshTokenProvider;

  /// Called with the rotated pair; the old refresh token is dead once /auth/refresh succeeds.
  final TokensSaver? onTokensRefreshed;

  /// Called when the server rejects the refresh token (revoked / expired / reused).
  final Future<void> Function()? onSessionExpired;

  Future<String?>? _refreshing;

  /// Concurrent 401s share one refresh call: refresh tokens are single-use, so a second
  /// parallel call would be treated as token reuse and revoke the whole session.
  Future<String?> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final refreshToken = await refreshTokenProvider!();
    if (refreshToken == null || refreshToken.isEmpty) {
      await onSessionExpired?.call();
      return null;
    }

    try {
      // Plain Dio (no interceptors) so a failing refresh can never loop.
      final plain = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        contentType: Headers.jsonContentType,
      ));
      final response = await plain.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      await onTokensRefreshed!(accessToken, data['refreshToken'] as String);
      return accessToken;
    } on DioException catch (e) {
      // Only an explicit rejection ends the session; a network error keeps it for a later retry.
      if (e.response?.statusCode == 401) await onSessionExpired?.call();
      return null;
    }
  }
}
