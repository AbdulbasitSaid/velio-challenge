part of 'plan_bloc.dart';

final class PlanState extends Equatable {
  const PlanState({
    this.plan,
    this.activity,
    this.live,
    this.realtime = RealtimeStatus.connecting,
    this.error,
    this.loading = false,
  });

  final PlanView? plan;
  final PublicActivity? activity;
  final LiveCount? live;
  final RealtimeStatus realtime;
  final LoadError? error;

  /// A load is in flight (ends pull to refresh).
  final bool loading;

  int get spots => live?.spotsLeft ?? activity?.spotsLeft ?? 0;

  PlanState copyWith({
    PlanView? plan,
    PublicActivity? activity,
    LiveCount? live,
    RealtimeStatus? realtime,
    LoadError? Function()? error,
    bool? loading,
  }) => PlanState(
    plan: plan ?? this.plan,
    activity: activity ?? this.activity,
    live: live ?? this.live,
    realtime: realtime ?? this.realtime,
    error: error != null ? error() : this.error,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [plan, activity, live, realtime, error, loading];
}
