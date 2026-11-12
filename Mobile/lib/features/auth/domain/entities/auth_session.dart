import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.token, this.email, this.refreshToken});

  /// Short-lived access token (JWT) sent on API calls.
  final String token;
  final String? email;

  /// Long-lived opaque token; only present right after login / refresh.
  final String? refreshToken;

  @override
  List<Object?> get props => [token, email, refreshToken];
}
