import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<String?> readToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  @override
  Future<String?> readToken() => _guard(() => _storage.read(key: _tokenKey));

  @override
  Future<String?> readRefreshToken() => _guard(() => _storage.read(key: _refreshTokenKey));

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) =>
      _guard(() async {
        await _storage.write(key: _tokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      });

  /// Removes both tokens.
  @override
  Future<void> clearToken() => _guard(() async {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _refreshTokenKey);
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const CacheException();
    }
  }
}
