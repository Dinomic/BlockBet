part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) the profile from the backend.
class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileSaved extends ProfileEvent {
  const ProfileSaved(this.update);
  final ProfileUpdate update;

  @override
  List<Object?> get props => [update];
}
