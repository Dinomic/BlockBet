import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<Profile, ProfileUpdate> {
  const UpdateProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> call(ProfileUpdate params) => _repository.updateProfile(params);
}
