part of 'attendance_bloc.dart';

final class AttendanceState extends Equatable {
  const AttendanceState({
    this.data,
    this.activity,
    this.error,
    this.live,
    this.realtime = RealtimeStatus.connecting,
    this.started = false,
    this.query = '',
    this.seen = const {},
    this.arrived = const {},
    this.flash,
    this.flashes = 0,
  });

  final Attendance? data;
  final PublicActivity? activity;
  final LoadError? error;

  /// Spots left, version-gated (rule 2).
  final LiveCount? live;
  final RealtimeStatus realtime;

  /// From the start time, marking replaces removal.
  final bool started;
  final String query;

  /// Every booking seen, and those that arrived after the first load.
  final Set<String> seen;
  final Set<String> arrived;

  /// The latest message for the snack bar; [flashes] counts them.
  final String? flash;
  final int flashes;

  bool get ready => data != null && activity != null;
  bool get reconnecting => realtime == RealtimeStatus.reconnecting;
  int get spotsLeft => live?.spotsLeft ?? data!.activity.spotsLeft;
  AttendanceStats get stats => attendanceStats(data!);
  bool get empty => data!.attendees.isEmpty;

  /// The rows in order, filtered by the search.
  List<Attendee> get rows =>
      orderAttendees(data!.attendees, started: started).where((a) => matchesGuest(a, query)).toList();

  AttendanceState copyWith({
    Attendance? Function()? data,
    PublicActivity? Function()? activity,
    LoadError? Function()? error,
    LiveCount? Function()? live,
    RealtimeStatus? realtime,
    bool? started,
    String? query,
    Set<String>? seen,
    Set<String>? arrived,
    String? Function()? flash,
    int? flashes,
  }) => AttendanceState(
    data: data != null ? data() : this.data,
    activity: activity != null ? activity() : this.activity,
    error: error != null ? error() : this.error,
    live: live != null ? live() : this.live,
    realtime: realtime ?? this.realtime,
    started: started ?? this.started,
    query: query ?? this.query,
    seen: seen ?? this.seen,
    arrived: arrived ?? this.arrived,
    flash: flash != null ? flash() : this.flash,
    flashes: flashes ?? this.flashes,
  );

  @override
  List<Object?> get props => [data, activity, error, live, realtime, started, query, seen, arrived, flash, flashes];
}
