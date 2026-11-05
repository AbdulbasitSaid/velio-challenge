part of 'profile_bloc.dart';

enum ProfileStatus { loading, success, failure }

final class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.loading, this.profile, this.error});

  final ProfileStatus status;
  final Profile? profile;
  final LoadError? error;

  @override
  List<Object?> get props => [status, profile, error];
}
