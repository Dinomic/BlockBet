import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<Profile, NoParams> {
  const GetProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> call(NoParams params) => _repository.getProfile();
}
