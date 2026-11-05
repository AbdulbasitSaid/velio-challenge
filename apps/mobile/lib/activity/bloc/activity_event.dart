part of 'activity_bloc.dart';

sealed class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, pull to refresh, Try again, a sign-in, or back from "You're in". [done] completes
/// when the load ends.
final class ActivityRequested extends ActivityEvent {
  const ActivityRequested({this.done});
  final Completer<void>? done;
}

/// After the first load: follow the activity's spots.
final class ActivityLiveSubscriptionRequested extends ActivityEvent {
  const ActivityLiveSubscriptionRequested();
}

final class ActivityLiveUpdated extends ActivityEvent {
  const ActivityLiveUpdated(this.update);
  final LiveUpdate update;

  @override
  List<Object?> get props => [update];
}

/// A live change moved the count: who's going is fetched again.
final class ActivityMembersRefreshRequested extends ActivityEvent {
  const ActivityMembersRefreshRequested();
}

final class ActivityNextStepsRequested extends ActivityEvent {
  const ActivityNextStepsRequested();
}

final class ActivityBookPressed extends ActivityEvent {
  const ActivityBookPressed();
}
