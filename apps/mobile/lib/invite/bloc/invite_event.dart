part of 'invite_bloc.dart';

sealed class InviteEvent extends Equatable {
  const InviteEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opened, or Try again.
final class InviteRequested extends InviteEvent {
  const InviteRequested();
}

final class InviteLiveUpdated extends InviteEvent {
  const InviteLiveUpdated(this.update);
  final LiveUpdate update;

  @override
  List<Object?> get props => [update];
}

/// The live invite's first frame was painted.
final class InviteShown extends InviteEvent {
  const InviteShown();
}

final class InviteNextStepsRequested extends InviteEvent {
  const InviteNextStepsRequested(this.activityId);
  final String activityId;

  @override
  List<Object?> get props => [activityId];
}
