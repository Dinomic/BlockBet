import 'package:bbmobile/core/error/failures.dart';
import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/core/usecase/usecase.dart';
import 'package:bbmobile/features/auth/domain/entities/auth_session.dart';
import 'package:bbmobile/features/auth/domain/usecases/get_session.dart';
import 'package:bbmobile/features/auth/domain/usecases/login.dart';
import 'package:bbmobile/features/auth/domain/usecases/logout.dart';
import 'package:bbmobile/features/auth/domain/usecases/sign_up.dart';
import 'package:bbmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSession extends Mock implements GetSession {}

class MockLogin extends Mock implements Login {}

class MockSignUp extends Mock implements SignUp {}

class MockLogout extends Mock implements Logout {}

void main() {
  late MockGetSession getSession;
  late MockLogin login;
  late MockSignUp signUp;
  late MockLogout logout;

  const loginParams = LoginParams(email: 'a@b.com', password: 'password1');
  const signUpParams = SignUpParams(email: 'a@b.com', password: 'password1');
  const session = AuthSession(token: 'jwt', email: 'a@b.com');
  const loginTitle = "Couldn't log you in";
  const signUpTitle = "Couldn't create your account";

  setUpAll(() {
    registerFallbackValue(loginParams);
    registerFallbackValue(signUpParams);
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getSession = MockGetSession();
    login = MockLogin();
    signUp = MockSignUp();
    logout = MockLogout();
  });

  AuthBloc build() =>
      AuthBloc(
        getSession: getSession,
        login: login,
        signUp: signUp,
        logout: logout,
        minSplashDuration: Duration.zero,
      );

  blocTest<AuthBloc, AuthState>(
    'login success -> authenticated with email',
    build: build,
    setUp: () => when(() => login(any())).thenAnswer((_) async => const Success(session)),
    act: (b) => b.add(const LoginSubmitted(email: 'a@b.com', password: 'password1')),
    expect: () => const [
      AuthState(isSubmitting: true),
      AuthState(status: AuthStatus.authenticated, email: 'a@b.com'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'login failure -> error title and message, stays unknown',
    build: build,
    setUp: () =>
        when(() => login(any())).thenAnswer((_) async => const Err(UnauthorizedFailure())),
    act: (b) => b.add(const LoginSubmitted(email: 'a@b.com', password: 'bad')),
    expect: () => const [
      AuthState(isSubmitting: true),
      AuthState(
        errorTitle: loginTitle,
        errorMessage: 'Email or password is incorrect. Check them and try again.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sign up success then auto login -> authenticated',
    build: build,
    setUp: () {
      when(() => signUp(any())).thenAnswer((_) async => const Success(null));
      when(() => login(any())).thenAnswer((_) async => const Success(session));
    },
    act: (b) => b.add(const SignUpSubmitted(email: 'a@b.com', password: 'password1')),
    expect: () => const [
      AuthState(isSubmitting: true),
      AuthState(status: AuthStatus.authenticated, email: 'a@b.com'),
    ],
    verify: (_) => verify(() => login(any())).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'sign up conflict does not attempt login',
    build: build,
    setUp: () =>
        when(() => signUp(any())).thenAnswer((_) async => const Err(EmailTakenFailure())),
    act: (b) => b.add(const SignUpSubmitted(email: 'a@b.com', password: 'password1')),
    expect: () => const [
      AuthState(isSubmitting: true),
      AuthState(
        errorTitle: signUpTitle,
        errorMessage: 'An account with this email already exists. Log in instead.',
      ),
    ],
    verify: (_) => verifyNever(() => login(any())),
  );

  blocTest<AuthBloc, AuthState>(
    'started with stored token -> authenticated',
    build: build,
    setUp: () => when(() => getSession(any())).thenAnswer((_) async => const Success(session)),
    act: (b) => b.add(const AuthStarted()),
    expect: () => const [AuthState(status: AuthStatus.authenticated, email: 'a@b.com')],
  );

  blocTest<AuthBloc, AuthState>(
    'started without token -> unauthenticated',
    build: build,
    setUp: () => when(() => getSession(any())).thenAnswer((_) async => const Success(null)),
    act: (b) => b.add(const AuthStarted()),
    expect: () => const [AuthState(status: AuthStatus.unauthenticated)],
  );

  blocTest<AuthBloc, AuthState>(
    'logout -> unauthenticated and email cleared',
    build: build,
    setUp: () => when(() => logout(any())).thenAnswer((_) async => const Success(null)),
    seed: () => const AuthState(status: AuthStatus.authenticated, email: 'a@b.com'),
    act: (b) => b.add(const LogoutRequested()),
    expect: () => const [AuthState(status: AuthStatus.unauthenticated)],
  );
}
