import '../../../../core/result.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> getProfile();

  /// Returns the profile as stored after the update.
  Future<Result<Profile>> updateProfile(ProfileUpdate update);
}
