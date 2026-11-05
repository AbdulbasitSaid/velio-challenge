part of 'explore_bloc.dart';

sealed class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, pull to refresh, or Try again. [done] completes when the load ends.
final class ExploreRequested extends ExploreEvent {
  const ExploreRequested({this.done});
  final Completer<void>? done;
}

/// After the first load: follow every card's activity.
final class ExploreLiveSubscriptionRequested extends ExploreEvent {
  const ExploreLiveSubscriptionRequested();
}

final class ExploreLiveUpdated extends ExploreEvent {
  const ExploreLiveUpdated(this.update);
  final LiveUpdate update;

  @override
  List<Object?> get props => [update];
}

/// The List / Map toggle.
final class ExploreViewToggled extends ExploreEvent {
  const ExploreViewToggled(this.showMap);
  final bool showMap;

  @override
  List<Object?> get props => [showMap];
}
