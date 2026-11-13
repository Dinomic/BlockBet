import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.remote});
  final ProfileRemoteDataSource remote;

  @override
  Future<Result<Profile>> getProfile() => _run(remote.getProfile);

  @override
  Future<Result<Profile>> updateProfile(ProfileUpdate update) =>
      _run(() => remote.updateProfile(update));

  Future<Result<Profile>> _run(Future<Profile> Function() action) async {
    try {
      return Success(await action());
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status == 401 || status == 403) {
        return const Err(ServerFailure('Your session has expired. Log in again.', statusCode: 401));
      }
      // 5xx: don't leak server internals.
      if (status != null && status >= 500) return const Err(NetworkFailure());
      return Err(ServerFailure(e.message, statusCode: status));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }
}
