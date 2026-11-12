import 'dart:convert';

import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.token, super.email, super.refreshToken});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) => AuthSessionModel(
        token: json['accessToken'] as String,
        email: _emailFromJwt(json['accessToken'] as String),
        refreshToken: json['refreshToken'] as String?,
      );

  /// The backend JWT carries an `email` claim; read it (without verifying) for display.
  factory AuthSessionModel.fromToken(String token) =>
      AuthSessionModel(token: token, email: _emailFromJwt(token));

  static String? _emailFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      return claims is Map ? claims['email'] as String? : null;
    } catch (_) {
      return null;
    }
  }
}
