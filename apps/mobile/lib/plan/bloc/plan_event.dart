part of 'plan_bloc.dart';

sealed class PlanEvent extends Equatable {
  const PlanEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opened, pull to refresh, or Try again.
final class PlanRequested extends PlanEvent {
  const PlanRequested();
}

final class PlanLiveUpdated extends PlanEvent {
  const PlanLiveUpdated(this.update);
  final LiveUpdate update;

  @override
  List<Object?> get props => [update];
}
