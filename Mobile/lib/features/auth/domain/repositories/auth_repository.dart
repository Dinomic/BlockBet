import '../../../../core/result.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<Result<AuthSession>> login({required String email, required String password});
  Future<Result<void>> signUp({required String email, required String password});
  Future<Result<AuthSession?>> getSession();
  Future<Result<void>> logout();
}
