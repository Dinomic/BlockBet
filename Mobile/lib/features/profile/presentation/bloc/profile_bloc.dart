import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required GetProfile getProfile, required UpdateProfile updateProfile})
      // ignore: prefer_initializing_formals
      : _getProfile = getProfile,
        // ignore: prefer_initializing_formals
        _updateProfile = updateProfile,
        super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileSaved>(_onSaved);
  }

  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  Future<void> _onRequested(ProfileRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    final result = await _getProfile(const NoParams());
    emit(result.when(
      success: (profile) => state.copyWith(status: ProfileStatus.loaded, profile: profile),
      failure: (f) => state.copyWith(status: ProfileStatus.failure, errorMessage: f.message),
    ));
  }

  Future<void> _onSaved(ProfileSaved event, Emitter<ProfileState> emit) async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _updateProfile(event.update);
    emit(result.when(
      success: (profile) => state.copyWith(
        isSaving: false,
        profile: profile,
        saveCount: state.saveCount + 1,
      ),
      failure: (f) => state.copyWith(isSaving: false, errorMessage: f.message),
    ));
  }
}
