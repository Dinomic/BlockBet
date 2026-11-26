import 'package:equatable/equatable.dart';

import 'user_role.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.token, this.email, this.refreshToken, this.roles = const []});

  /// Short-lived access token (JWT) sent on API calls.
  final String token;
  final String? email;

  /// Long-lived opaque token; only present right after login / refresh.
  final String? refreshToken;

  /// Roles of the account, read from the token's `roles` claim.
  final List<UserRole> roles;

  @override
  List<Object?> get props => [token, email, refreshToken, roles];
}
