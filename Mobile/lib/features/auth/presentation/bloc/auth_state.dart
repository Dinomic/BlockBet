part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.email,
    this.isSubmitting = false,
    this.errorTitle,
    this.errorMessage,
  });

  final AuthStatus status;

  /// Email of the signed-in user (from the JWT), when authenticated.
  final String? email;
  final bool isSubmitting;
  final String? errorTitle;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    bool? isSubmitting,
    String? errorTitle,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorTitle: clearError ? null : (errorTitle ?? this.errorTitle),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, email, isSubmitting, errorTitle, errorMessage];
}
