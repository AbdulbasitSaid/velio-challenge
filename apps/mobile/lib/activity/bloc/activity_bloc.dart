// B1 activity page (S7b FR-004, FR-005; web activity-live.tsx): live spots under the six realtime
// rules, who's going refetched after a spots change, and Book with one Idempotency-Key per attempt:
// "Booking…" at once, success only when the API confirms (PRD M3).
import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/booking.dart';
import '../../domain/live.dart';
import '../../domain/load_error.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/session_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc({
    required ActivityRepository activityRepository,
    required LiveRepository liveRepository,
    required SessionRepository sessionRepository,
    required String id,
    Random? random,
  }) : _activities = activityRepository,
       _live = liveRepository,
       _session = sessionRepository,
       _activityId = id,
       _random = random ?? Random(),
       super(const ActivityState()) {
    on<ActivityRequested>(_onRequested);
    on<ActivityLiveSubscriptionRequested>(_onLiveSubscriptionRequested);
    on<ActivityLiveUpdated>(_onLiveUpdated);
    on<ActivityMembersRefreshRequested>(_onMembersRefreshRequested);
    on<ActivityNextStepsRequested>(_onNextStepsRequested);
    on<ActivityBookPressed>(_onBookPressed, transformer: droppable());
    // Signing in from Book comes back here: the viewer's state changes with it.
    _sessionSub = _session.changes.listen((_) => add(const ActivityRequested()));
  }

  final ActivityRepository _activities;
  final LiveRepository _live;
  final SessionRepository _session;
  final String _activityId;
  final Random _random;
  late final StreamSubscription<LocalProfile?> _sessionSub;
  Timer? _membersTimer;
  bool _subscribed = false;
  bool _nextRequested = false;

  Future<void> _onRequested(ActivityRequested event, Emitter<ActivityState> emit) async {
    // Try again from the error screen shows the skeleton.
    if (state.status == ActivityStatus.failure) emit(state.copyWith(status: ActivityStatus.loading, clearError: true));
    try {
      final a = await _activities.activity(_activityId);
      final live = state.live;
      emit(
        state.copyWith(
          status: ActivityStatus.success,
          activity: a,
          members: a.members,
          live: live == null
              ? LiveCount(spotsLeft: a.spotsLeft, version: a.version)
              : live.apply(a.spotsLeft, a.version) ?? live,
          clearError: true,
        ),
      );
      if (!_subscribed) {
        _subscribed = true;
        add(const ActivityLiveSubscriptionRequested());
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: state.activity == null ? ActivityStatus.failure : state.status,
          error: LoadError.of(e, notFound: const {404, 400}),
        ),
      );
    } finally {
      event.done?.complete();
    }
  }

  Future<void> _onLiveSubscriptionRequested(ActivityLiveSubscriptionRequested event, Emitter<ActivityState> emit) {
    emit(state.copyWith(realtime: _live.status));
    return emit.onEach(_live.watch(['activity:$_activityId']), onData: (u) => add(ActivityLiveUpdated(u)));
  }

  void _onLiveUpdated(ActivityLiveUpdated event, Emitter<ActivityState> emit) {
    switch (event.update) {
      case LiveSpotsChanged(:final activityId, :final spotsLeft, :final version):
        final next = state.live?.apply(spotsLeft, version, fromEvent: true);
        if (next == null) return;
        emit(state.copyWith(live: next));
        _live.rendered(activityId, version);
        // A `spots` event carries only the count, so who's going is fetched again. A random 0–2 s delay
        // spreads the refetch when many people watch one activity; a newer change replaces the pending one.
        if (next.changed) {
          _membersTimer?.cancel();
          _membersTimer = Timer(
            Duration(milliseconds: _random.nextInt(2000)),
            () => add(const ActivityMembersRefreshRequested()),
          );
        }
      case LiveStatusChanged(:final status):
        emit(state.copyWith(realtime: status));
      case LiveRefreshRequested():
        add(const ActivityRequested());
      case LivePlanChanged() || LiveAttendanceChanged():
        break;
    }
  }

  Future<void> _onMembersRefreshRequested(ActivityMembersRefreshRequested event, Emitter<ActivityState> emit) async {
    try {
      final fresh = await _activities.activity(_activityId);
      emit(state.copyWith(members: fresh.members));
    } on ApiException {
      // The next change refetches again.
    }
  }

  Future<void> _onNextStepsRequested(ActivityNextStepsRequested event, Emitter<ActivityState> emit) async {
    try {
      emit(state.copyWith(next: await _activities.nextSteps(_activityId)));
    } on ApiException {
      // Next steps are extras (UX FR-007); asked again on the next change.
      _nextRequested = false;
    }
  }

  Future<void> _onBookPressed(ActivityBookPressed event, Emitter<ActivityState> emit) async {
    if (!_session.signedIn) {
      emit(state.withEffect(ActivityEffect.signIn));
      return;
    }
    emit(state.copyWith(attempt: BookingAttempt.booking));
    try {
      final res = await _activities.book(_activityId);
      await _activities.clearAttempt(_activityId);
      emit(
        state
            .copyWith(attempt: BookingAttempt.idle, bookedPlanId: res.booking.planId)
            .withEffect(ActivityEffect.booked),
      );
    } on ApiException catch (err) {
      final outcome = bookingOutcome(err);
      if (outcome != BookingOutcome.error) await _activities.clearAttempt(_activityId);
      switch (outcome) {
        case BookingOutcome.signIn:
          emit(state.copyWith(attempt: BookingAttempt.idle).withEffect(ActivityEffect.signIn));
        case BookingOutcome.refresh:
          emit(state.copyWith(attempt: BookingAttempt.idle));
          add(const ActivityRequested());
        case BookingOutcome.soldOut:
          emit(state.copyWith(attempt: BookingAttempt.soldOut).withEffect(ActivityEffect.soldOut));
        case BookingOutcome.started:
          emit(state.copyWith(attempt: BookingAttempt.started));
        case BookingOutcome.paused:
          emit(state.copyWith(attempt: BookingAttempt.paused));
        case BookingOutcome.error:
          emit(state.copyWith(attempt: BookingAttempt.error));
      }
    }
  }

  /// Removed, started or sold out: the host's other dates and more in the community, once.
  @override
  void onChange(Change<ActivityState> change) {
    super.onChange(change);
    final s = change.nextState;
    if (s.needsNextSteps && s.next == null && !_nextRequested && !isClosed) {
      _nextRequested = true;
      add(const ActivityNextStepsRequested());
    }
  }

  @override
  Future<void> close() {
    _membersTimer?.cancel();
    _sessionSub.cancel();
    return super.close();
  }
}
