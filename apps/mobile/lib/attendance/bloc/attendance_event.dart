part of 'attendance_bloc.dart';

sealed class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, came back from editing, or Try again.
final class AttendanceRequested extends AttendanceEvent {
  const AttendanceRequested();
}

/// Pull to refresh; [done] completes after.
final class AttendanceRefreshed extends AttendanceEvent {
  const AttendanceRefreshed({this.done});
  final Completer<void>? done;
}

final class AttendanceLiveUpdated extends AttendanceEvent {
  const AttendanceLiveUpdated(this.update);
  final LiveUpdate update;

  @override
  List<Object?> get props => [update];
}

/// The start time arrived (or had passed at load, with no refetch).
final class AttendanceStarted extends AttendanceEvent {
  const AttendanceStarted({this.refetch = true});
  final bool refetch;

  @override
  List<Object?> get props => [refetch];
}

final class AttendanceQueryChanged extends AttendanceEvent {
  const AttendanceQueryChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

final class AttendanceMarkPressed extends AttendanceEvent {
  const AttendanceMarkPressed(this.attendee, this.mark);
  final Attendee attendee;
  final AttendanceMark mark;

  @override
  List<Object?> get props => [attendee.bookingId, mark];
}

/// The host confirmed Remove in the sheet.
final class AttendanceRemoveConfirmed extends AttendanceEvent {
  const AttendanceRemoveConfirmed(this.attendee);
  final Attendee attendee;

  @override
  List<Object?> get props => [attendee.bookingId];
}
