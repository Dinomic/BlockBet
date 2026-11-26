part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.email,
    this.roles = const [],
    this.isSubmitting = false,
    this.errorTitle,
    this.errorMessage,
  });

  final AuthStatus status;

  /// Email of the signed-in user (from the JWT), when authenticated.
  final String? email;

  /// Roles of the signed-in user (from the JWT), highest privilege first.
  final List<UserRole> roles;
  final bool isSubmitting;
  final String? errorTitle;
  final String? errorMessage;

  bool get isBettor => roles.contains(UserRole.bettor);
  bool get isBookie => roles.contains(UserRole.bookie);

  /// The role to headline in the UI (null while the token carries none).
  UserRole? get primaryRole => roles.isEmpty ? null : roles.first;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    List<UserRole>? roles,
    bool? isSubmitting,
    String? errorTitle,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorTitle: clearError ? null : (errorTitle ?? this.errorTitle),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, email, roles, isSubmitting, errorTitle, errorMessage];
}
