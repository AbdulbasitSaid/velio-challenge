// P1 profile (S7 FR-017): loads a person's public profile.
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/load_error.dart';
import '../../repositories/plan_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required PlanRepository planRepository, required this.userId})
    : _plans = planRepository,
      super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
  }

  final PlanRepository _plans;
  final String userId;

  Future<void> _onRequested(ProfileRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileState());
    try {
      emit(ProfileState(status: ProfileStatus.success, profile: await _plans.profile(userId)));
    } on ApiException catch (e) {
      emit(ProfileState(status: ProfileStatus.failure, error: LoadError.of(e)));
    }
  }
}
