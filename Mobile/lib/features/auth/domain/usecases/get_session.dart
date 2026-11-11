import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GetSession implements UseCase<AuthSession?, NoParams> {
  const GetSession(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthSession?>> call(NoParams params) => _repository.getSession();
}
