import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/sign_up.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetSession getSession,
    required Login login,
    required SignUp signUp,
    required Logout logout,
    this.minSplashDuration = const Duration(seconds: 1),
    // ignore: prefer_initializing_formals
  })  : _getSession = getSession,
        // ignore: prefer_initializing_formals
        _login = login,
        // ignore: prefer_initializing_formals
        _signUp = signUp,
        // ignore: prefer_initializing_formals
        _logout = logout,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLogin);
    on<SignUpSubmitted>(_onSignUp);
    on<LogoutRequested>(_onLogout);
    on<AuthErrorDismissed>((_, emit) => emit(state.copyWith(clearError: true)));
  }

  final GetSession _getSession;
  final Login _login;
  final SignUp _signUp;
  final Logout _logout;

  /// The splash screen stays visible at least this long, even if the session check is faster.
  final Duration minSplashDuration;

  static const _loginErrorTitle = "Couldn't log you in";
  static const _signUpErrorTitle = "Couldn't create your account";

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final (result, _) = await (
      _getSession(const NoParams()),
      Future<void>.delayed(minSplashDuration),
    ).wait;
    emit(result.when(
      success: (session) => session == null
          ? state.copyWith(status: AuthStatus.unauthenticated)
          : state.copyWith(status: AuthStatus.authenticated, email: session.email),
      failure: (_) => state.copyWith(status: AuthStatus.unauthenticated),
    ));
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _login(LoginParams(email: event.email.trim(), password: event.password));
    emit(result.when(
      success: (s) => state.copyWith(
        status: AuthStatus.authenticated,
        email: s.email ?? event.email.trim(),
        isSubmitting: false,
      ),
      failure: (f) => state.copyWith(
        isSubmitting: false,
        errorTitle: _loginErrorTitle,
        errorMessage: f.message,
      ),
    ));
  }

  /// Backend sign-up returns no token, so we log in right after a successful sign-up.
  Future<void> _onSignUp(SignUpSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final email = event.email.trim();
    final signUpResult = await _signUp(SignUpParams(email: email, password: event.password));

    final failure = signUpResult.when<String?>(success: (_) => null, failure: (f) => f.message);
    if (failure != null) {
      emit(state.copyWith(
        isSubmitting: false,
        errorTitle: _signUpErrorTitle,
        errorMessage: failure,
      ));
      return;
    }

    final loginResult = await _login(LoginParams(email: email, password: event.password));
    emit(loginResult.when(
      success: (s) => state.copyWith(
        status: AuthStatus.authenticated,
        email: s.email ?? email,
        isSubmitting: false,
      ),
      failure: (f) => state.copyWith(
        isSubmitting: false,
        errorTitle: _signUpErrorTitle,
        errorMessage: f.message,
      ),
    ));
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _logout(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
