part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Clears a displayed error, e.g. when switching between login and sign-up.
class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}
