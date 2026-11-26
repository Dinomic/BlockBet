import 'dart:convert';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.token, super.email, super.refreshToken, super.roles});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String;
    final claims = _claims(token);
    return AuthSessionModel(
      token: token,
      email: _email(claims),
      refreshToken: json['refreshToken'] as String?,
      roles: _roles(claims),
    );
  }

  /// The backend JWT carries `email` and `roles` claims; read them (without verifying) for display.
  factory AuthSessionModel.fromToken(String token) {
    final claims = _claims(token);
    return AuthSessionModel(token: token, email: _email(claims), roles: _roles(claims));
  }

  static Map<dynamic, dynamic>? _claims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      return claims is Map ? claims : null;
    } catch (_) {
      return null;
    }
  }

  static String? _email(Map<dynamic, dynamic>? claims) {
    final email = claims?['email'];
    return email is String ? email : null;
  }

  static List<UserRole> _roles(Map<dynamic, dynamic>? claims) {
    final roles = claims?['roles'];
    if (roles is! List) return const [];
    return UserRole.sorted(roles.map(UserRole.fromClaim).whereType<UserRole>());
  }
}
