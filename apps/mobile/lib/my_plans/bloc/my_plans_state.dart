part of 'my_plans_bloc.dart';

final class MyPlansState extends Equatable {
  const MyPlansState({
    required this.signedIn,
    this.plans,
    this.cachedAt,
    this.offline = false,
    this.error,
    this.past = false,
    this.loading = false,
  });

  final bool signedIn;
  final MyPlans? plans;

  /// When the saved list shown offline was fetched.
  final DateTime? cachedAt;
  final bool offline;
  final LoadError? error;

  /// Past or Upcoming.
  final bool past;

  /// A load is in flight (ends pull to refresh).
  final bool loading;

  MyPlansState copyWith({
    bool? signedIn,
    MyPlans? Function()? plans,
    DateTime? Function()? cachedAt,
    bool? offline,
    LoadError? Function()? error,
    bool? past,
    bool? loading,
  }) => MyPlansState(
    signedIn: signedIn ?? this.signedIn,
    plans: plans != null ? plans() : this.plans,
    cachedAt: cachedAt != null ? cachedAt() : this.cachedAt,
    offline: offline ?? this.offline,
    error: error != null ? error() : this.error,
    past: past ?? this.past,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [signedIn, plans, cachedAt, offline, error, past, loading];
}
