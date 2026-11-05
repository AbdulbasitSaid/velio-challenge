// H1 live attendance (S7b FR-011, FR-012; web attendance-live.tsx; PRD H1, H2, D3, D5). Follows
// `activity:<id>` for spots and `host:<id>` for bookings; an `attendance` event carries only the ID,
// so the list is fetched again (rule 5). Before the start a guest can be removed; from the start,
// marked attended or no-show, optimistically, with the latest mark winning.
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/attendance.dart';
import '../../domain/format.dart';
import '../../domain/live.dart';
import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';
import '../../repositories/live_repository.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

/// setTimeout's ceiling on the web; a start further out is caught by the next load instead.
const _maxTimer = Duration(milliseconds: 2147483647);

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc({
    required HostRepository hostRepository,
    required LiveRepository liveRepository,
    required String activityId,
    this._clock = DateTime.now,
  }) : _host = hostRepository,
       _live = liveRepository,
       _id = activityId,
       super(AttendanceState(realtime: liveRepository.status)) {
    on<AttendanceRequested>(_onRequested);
    on<AttendanceRefreshed>(_onRefreshed);
    on<AttendanceLiveUpdated>(_onLiveUpdated);
    on<AttendanceStarted>(_onStarted);
    on<AttendanceQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<AttendanceMarkPressed>(_onMarkPressed, transformer: sequential());
    on<AttendanceRemoveConfirmed>(_onRemoveConfirmed, transformer: sequential());
  }

  final HostRepository _host;
  final LiveRepository _live;
  final String _id;
  final DateTime Function() _clock;
  bool _watching = false;
  Timer? _startTimer;

  Future<void> _onRequested(AttendanceRequested event, Emitter<AttendanceState> emit) async {
    emit(state.copyWith(error: () => null));
    final Attendance data;
    final PublicActivity activity;
    try {
      (data, activity) = await (_host.attendance(_id), _host.activity(_id)).wait;
    } on ParallelWaitError<(Attendance?, PublicActivity?), (AsyncError?, AsyncError?)> catch (e) {
      _failed(emit, e.errors.$1?.error ?? e.errors.$2?.error ?? 'unknown');
      return;
    } on ApiException catch (e) {
      _failed(emit, e);
      return;
    }
    emit(_applied(state, data).copyWith(activity: () => activity));
    _watchStart(data.activity);
    if (_watching) return;
    _watching = true;
    emit(
      state.copyWith(
        live: () => LiveCount(spotsLeft: data.activity.spotsLeft, version: data.activity.version),
      ),
    );
    await emit.onEach(_live.watch(['activity:$_id', 'host:$_id']), onData: (u) => add(AttendanceLiveUpdated(u)));
  }

  void _failed(Emitter<AttendanceState> emit, Object err) =>
      emit(state.copyWith(error: () => LoadError.of(ApiException.from(err), notFound: const {400, 403, 404})));

  /// The new list, noting bookings that arrived since the first load ("Booked just now").
  AttendanceState _applied(AttendanceState s, Attendance fresh) {
    final first = s.data == null;
    final seen = {...s.seen}, arrived = {...s.arrived};
    for (final a in fresh.attendees) {
      if (seen.add(a.bookingId) && !first) arrived.add(a.bookingId);
    }
    return s.copyWith(data: () => fresh, seen: seen, arrived: arrived);
  }

  /// Fetches the list again (with its spots); failures keep what's shown.
  Future<void> _refetch(Emitter<AttendanceState> emit) async {
    try {
      final fresh = await _host.attendance(_id);
      final live = state.live?.apply(fresh.activity.spotsLeft, fresh.activity.version);
      emit(_applied(state, fresh).copyWith(live: live == null ? null : () => live));
    } catch (_) {}
  }

  Future<void> _onRefreshed(AttendanceRefreshed event, Emitter<AttendanceState> emit) async {
    await _refetch(emit);
    event.done?.complete();
  }

  Future<void> _onLiveUpdated(AttendanceLiveUpdated event, Emitter<AttendanceState> emit) async {
    switch (event.update) {
      case LiveSpotsChanged(:final activityId, :final spotsLeft, :final version):
        final live = state.live?.apply(spotsLeft, version, fromEvent: true);
        if (live == null) return;
        emit(state.copyWith(live: () => live));
        _live.rendered(activityId, version);
      case LiveRefreshRequested() || LiveAttendanceChanged():
        await _refetch(emit);
      case LiveStatusChanged(:final status):
        emit(state.copyWith(realtime: status));
      case LivePlanChanged():
        break;
    }
  }

  /// Marking opens at the start (PRD H2): the screen flips then, and fetches once so marks made
  /// elsewhere show.
  void _watchStart(AttendanceActivity a) {
    if (state.started || _startTimer != null) return;
    if (a.started) {
      add(const AttendanceStarted(refetch: false));
      return;
    }
    final wait = a.startsAt.difference(_clock());
    if (wait > _maxTimer) return;
    _startTimer = Timer(wait.isNegative ? Duration.zero : wait, () => add(const AttendanceStarted()));
  }

  Future<void> _onStarted(AttendanceStarted event, Emitter<AttendanceState> emit) async {
    emit(state.copyWith(started: true));
    if (event.refetch) await _refetch(emit);
  }

  void _put(Emitter<AttendanceState> emit, Attendee m) {
    final d = state.data!;
    emit(
      state.copyWith(
        data: () => Attendance(
          activity: d.activity,
          attendees: [for (final x in d.attendees) x.bookingId == m.bookingId ? m : x],
        ),
      ),
    );
  }

  Future<void> _onMarkPressed(AttendanceMarkPressed event, Emitter<AttendanceState> emit) async {
    final a = event.attendee;
    if (a.mark == event.mark) return;
    _put(emit, Attendee.fromJson({...a.toJson(), 'mark': event.mark.value}));
    try {
      _put(emit, await _host.mark(a.bookingId, event.mark));
    } catch (err) {
      _put(emit, a);
      _flash(emit, markFailure(err, a.person.displayName));
      if (ApiException.from(err).code == 'booking_removed') await _refetch(emit);
    }
  }

  Future<void> _onRemoveConfirmed(AttendanceRemoveConfirmed event, Emitter<AttendanceState> emit) async {
    final name = firstName(event.attendee.person.displayName);
    try {
      await _host.remove(event.attendee.bookingId);
      await _refetch(emit);
      _flash(emit, '$name removed. Their spot is open again.');
    } catch (err) {
      _flash(
        emit,
        ApiException.from(err).network
            ? 'You’re offline. Reconnect to remove a guest.'
            : 'We couldn’t remove $name. Try again.',
      );
    }
  }

  void _flash(Emitter<AttendanceState> emit, String text) =>
      emit(state.copyWith(flash: () => text, flashes: state.flashes + 1));

  @override
  Future<void> close() {
    _startTimer?.cancel();
    return super.close();
  }
}
