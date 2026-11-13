part of 'profile_bloc.dart';

enum ProfileStatus { loading, loaded, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.isSaving = false,
    this.errorMessage,
    this.saveCount = 0,
  });

  final ProfileStatus status;
  final Profile? profile;
  final bool isSaving;

  /// Load error (status `failure`) or the last save error (status `loaded`).
  final String? errorMessage;

  /// Incremented after every successful save, so the UI can react once per save.
  final int saveCount;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    bool? isSaving,
    String? errorMessage,
    int? saveCount,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveCount: saveCount ?? this.saveCount,
    );
  }

  @override
  List<Object?> get props => [status, profile, isSaving, errorMessage, saveCount];
}
