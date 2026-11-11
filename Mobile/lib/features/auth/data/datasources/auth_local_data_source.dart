import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  @override
  Future<String?> readToken() => _guard(() => _storage.read(key: _tokenKey));

  @override
  Future<void> saveToken(String token) =>
      _guard(() => _storage.write(key: _tokenKey, value: token));

  @override
  Future<void> clearToken() => _guard(() => _storage.delete(key: _tokenKey));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const CacheException();
    }
  }
}
