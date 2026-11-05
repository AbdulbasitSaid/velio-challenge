part of 'activity_bloc.dart';

enum ActivityStatus { loading, success, failure }

/// The current Book attempt.
enum BookingAttempt { idle, booking, soldOut, error, started, paused }

/// One-shot results for the view: sign in first, booked (haptic and "You're in"), or sold out (haptic).
enum ActivityEffect { signIn, booked, soldOut }

final class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.activity,
    this.members,
    this.live,
    this.realtime,
    this.next,
    this.attempt = BookingAttempt.idle,
    this.error,
    this.effect,
    this.effectId = 0,
    this.bookedPlanId,
  });

  final ActivityStatus status;
  final PublicActivity? activity;

  /// Who's going, refetched after a live change.
  final PublicActivityMembers? members;
  final LiveCount? live;

  /// Null until the first load subscribes.
  final RealtimeStatus? realtime;
  final NextSteps? next;
  final BookingAttempt attempt;
  final LoadError? error;
  final ActivityEffect? effect;

  /// Bumped with each [effect], so the same effect twice is seen twice.
  final int effectId;

  /// The Plan of the booking just made.
  final String? bookedPlanId;

  int get spots => live?.spotsLeft ?? activity?.spotsLeft ?? 0;
  bool get reconnecting => realtime == RealtimeStatus.reconnecting;
  PublicActivityViewerBooking? get booking => activity?.viewer?.booking;
  bool get isHost => activity?.viewer?.isHost ?? false;
  bool get going => booking?.status == PublicActivityViewerBookingStatusEnum.confirmed;
  bool get removed => booking?.status == PublicActivityViewerBookingStatusEnum.removed;
  bool get started => activity?.status == PublicActivityStatusEnum.started || attempt == BookingAttempt.started;
  bool get paused => (activity?.bookingsPaused ?? false) || attempt == BookingAttempt.paused;
  bool get soldOut => spots <= 0 || attempt == BookingAttempt.soldOut;
  bool get needsNextSteps => activity != null && (removed || started || (soldOut && booking == null));

  ActivityState copyWith({
    ActivityStatus? status,
    PublicActivity? activity,
    PublicActivityMembers? members,
    LiveCount? live,
    RealtimeStatus? realtime,
    NextSteps? next,
    BookingAttempt? attempt,
    LoadError? error,
    bool clearError = false,
    String? bookedPlanId,
  }) => ActivityState(
    status: status ?? this.status,
    activity: activity ?? this.activity,
    members: members ?? this.members,
    live: live ?? this.live,
    realtime: realtime ?? this.realtime,
    next: next ?? this.next,
    attempt: attempt ?? this.attempt,
    error: clearError ? null : error ?? this.error,
    effect: effect,
    effectId: effectId,
    bookedPlanId: bookedPlanId ?? this.bookedPlanId,
  );

  ActivityState withEffect(ActivityEffect effect) => ActivityState(
    status: status,
    activity: activity,
    members: members,
    live: live,
    realtime: realtime,
    next: next,
    attempt: attempt,
    error: error,
    effect: effect,
    effectId: effectId + 1,
    bookedPlanId: bookedPlanId,
  );

  @override
  List<Object?> get props => [
    status,
    activity,
    members,
    live,
    realtime,
    next,
    attempt,
    error,
    effect,
    effectId,
    bookedPlanId,
  ];
}
