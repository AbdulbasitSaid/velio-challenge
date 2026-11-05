part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, or Try again.
final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}
