import 'package:bbmobile/core/error/failures.dart';
import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/core/usecase/usecase.dart';
import 'package:bbmobile/features/profile/data/models/profile_model.dart';
import 'package:bbmobile/features/profile/domain/entities/profile.dart';
import 'package:bbmobile/features/profile/domain/usecases/get_profile.dart';
import 'package:bbmobile/features/profile/domain/usecases/update_profile.dart';
import 'package:bbmobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProfile extends Mock implements GetProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

void main() {
  late MockGetProfile getProfile;
  late MockUpdateProfile updateProfile;

  const profile = Profile(email: 'a@b.com', displayName: 'Ann');
  const update = ProfileUpdate(displayName: 'Anna');
  const saved = Profile(email: 'a@b.com', displayName: 'Anna');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ProfileUpdate());
  });

  setUp(() {
    getProfile = MockGetProfile();
    updateProfile = MockUpdateProfile();
  });

  ProfileBloc build() => ProfileBloc(getProfile: getProfile, updateProfile: updateProfile);

  blocTest<ProfileBloc, ProfileState>(
    'load success -> loaded with profile',
    setUp: () => when(() => getProfile(any())).thenAnswer((_) async => const Success(profile)),
    build: build,
    act: (b) => b.add(const ProfileRequested()),
    expect: () => [
      const ProfileState(status: ProfileStatus.loading),
      const ProfileState(status: ProfileStatus.loaded, profile: profile),
    ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'load failure -> failure with message',
    setUp: () => when(() => getProfile(any())).thenAnswer((_) async => const Err(NetworkFailure('offline'))),
    build: build,
    act: (b) => b.add(const ProfileRequested()),
    expect: () => [
      const ProfileState(status: ProfileStatus.loading),
      const ProfileState(status: ProfileStatus.failure, errorMessage: 'offline'),
    ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'save success -> stored profile replaces old one and saveCount increments',
    setUp: () => when(() => updateProfile(any())).thenAnswer((_) async => const Success(saved)),
    build: build,
    seed: () => const ProfileState(status: ProfileStatus.loaded, profile: profile),
    act: (b) => b.add(const ProfileSaved(update)),
    expect: () => [
      const ProfileState(status: ProfileStatus.loaded, profile: profile, isSaving: true),
      const ProfileState(status: ProfileStatus.loaded, profile: saved, saveCount: 1),
    ],
    verify: (_) => verify(() => updateProfile(update)).called(1),
  );

  blocTest<ProfileBloc, ProfileState>(
    'save failure -> keeps profile, exposes error, no saveCount change',
    setUp: () => when(() => updateProfile(any())).thenAnswer((_) async => const Err(ServerFailure('bad phone'))),
    build: build,
    seed: () => const ProfileState(status: ProfileStatus.loaded, profile: profile),
    act: (b) => b.add(const ProfileSaved(update)),
    expect: () => [
      const ProfileState(status: ProfileStatus.loaded, profile: profile, isSaving: true),
      const ProfileState(status: ProfileStatus.loaded, profile: profile, errorMessage: 'bad phone'),
    ],
  );

  group('ProfileModel', () {
    test('fromJson parses fields, date and gender', () {
      final model = ProfileModel.fromJson({
        'email': 'a@b.com',
        'name': 'a@b.com',
        'displayName': 'Ann',
        'nationality': 'VN',
        'dateOfBirth': '1998-03-07',
        'gender': 'FEMALE',
      });
      expect(model.displayName, 'Ann');
      expect(model.nationality, 'VN');
      expect(model.dateOfBirth, DateTime(1998, 3, 7));
      expect(model.gender, Gender.female);
      expect(model.phone, isNull);
    });

    test('updateToJson sends only provided fields, date as yyyy-MM-dd', () {
      final json = ProfileModel.updateToJson(
        ProfileUpdate(displayName: 'Ann', dateOfBirth: DateTime(1998, 3, 7), gender: Gender.other),
      );
      expect(json, {'displayName': 'Ann', 'dateOfBirth': '1998-03-07', 'gender': 'OTHER'});
    });
  });
}
