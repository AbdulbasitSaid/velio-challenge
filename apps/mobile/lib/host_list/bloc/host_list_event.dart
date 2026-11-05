part of 'host_list_bloc.dart';

sealed class HostListEvent extends Equatable {
  const HostListEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, came back into view, Try again, or pull to refresh ([done] completes after).
final class HostListRequested extends HostListEvent {
  const HostListRequested({this.done});
  final Completer<void>? done;
}

final class HostListSessionSubscriptionRequested extends HostListEvent {
  const HostListSessionSubscriptionRequested();
}

final class HostListSessionChanged extends HostListEvent {
  const HostListSessionChanged();
}

/// Upcoming or Past.
final class HostListPastToggled extends HostListEvent {
  const HostListPastToggled(this.past);
  final bool past;

  @override
  List<Object?> get props => [past];
}
