import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.local});
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) {
    return _run(() async {
      final session = await remote.login(email: email, password: password);
      await local.saveTokens(
        accessToken: session.token,
        refreshToken: session.refreshToken ?? '',
      );
      return session;
    });
  }

  @override
  Future<Result<void>> signUp({required String email, required String password}) {
    return _run(() => remote.signUp(email: email, password: password));
  }

  @override
  Future<Result<AuthSession?>> getSession() {
    return _run(() async {
      final token = await local.readToken();
      return token == null ? null : AuthSessionModel.fromToken(token);
    });
  }

  @override
  Future<Result<void>> logout() {
    return _run(() async {
      // Best effort: revoke on the server, but always clear local tokens so the user
      // is logged out even when offline or the token is already invalid.
      final refreshToken = await local.readRefreshToken();
      try {
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await remote.logout(refreshToken: refreshToken);
        }
      } on ServerException catch (_) {
        // Server rejected / unreachable: nothing more to do, fall through.
      } on NetworkException catch (_) {
        // Offline: the refresh token will expire server-side on its own.
      } finally {
        await local.clearToken();
      }
    });
  }

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status == 401 || status == 403) return const Err(UnauthorizedFailure());
      if (status == 409) return const Err(EmailTakenFailure());
      // 5xx: don't leak server internals, show the generic connectivity message.
      if (status != null && status >= 500) return const Err(NetworkFailure());
      return Err(ServerFailure(e.message, statusCode: status));
    } on NetworkException {
      return const Err(NetworkFailure());
    } on CacheException {
      return const Err(CacheFailure());
    }
  }
}
