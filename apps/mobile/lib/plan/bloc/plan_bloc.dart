// G4 You're in and B4 Plan (S7 FR-011, FR-013): the Plan with its activity snapshot (the Plan view
// carries no location), live spots, and a refetch when the Plan changes (realtime rule 5).
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/live.dart';
import '../../domain/load_error.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/plan_repository.dart';

part 'plan_event.dart';
part 'plan_state.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  PlanBloc({required PlanRepository planRepository, required LiveRepository liveRepository, required this._planId})
    : _plans = planRepository,
      _live = liveRepository,
      super(const PlanState()) {
    on<PlanRequested>(_onRequested);
    on<PlanLiveUpdated>(_onLiveUpdated, transformer: sequential());
  }

  final PlanRepository _plans;
  final LiveRepository _live;
  final String _planId;
  bool _watching = false;

  Future<void> _onRequested(PlanRequested event, Emitter<PlanState> emit) async {
    emit(state.copyWith(error: () => null, loading: true));
    if (!await _load(emit) || _watching) return;
    _watching = true;
    emit(state.copyWith(realtime: _live.status));
    await emit.onEach(
      _live.watch(['activity:${state.activity!.id}', 'plan:$_planId']),
      onData: (u) => add(PlanLiveUpdated(u)),
    );
  }

  /// False when the load failed.
  Future<bool> _load(Emitter<PlanState> emit) async {
    try {
      final plan = await _plans.plan(_planId);
      final a = await _plans.activity(plan.activity.id);
      final current = state.live;
      final live = current == null
          ? LiveCount(spotsLeft: a.spotsLeft, version: a.version)
          : current.apply(a.spotsLeft, a.version) ?? current;
      emit(state.copyWith(plan: plan, activity: a, live: live, error: () => null, loading: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: () => _errorOf(e), loading: false));
      return false;
    }
  }

  Future<void> _onLiveUpdated(PlanLiveUpdated event, Emitter<PlanState> emit) async {
    switch (event.update) {
      case LiveSpotsChanged(:final activityId, :final spotsLeft, :final version):
        final next = state.live?.apply(spotsLeft, version, fromEvent: true);
        if (next == null) return;
        emit(state.copyWith(live: next));
        _live.rendered(activityId, version);
      case LiveRefreshRequested() || LivePlanChanged():
        await _load(emit);
      case LiveStatusChanged(:final status):
        emit(state.copyWith(realtime: status));
      case LiveAttendanceChanged():
        break;
    }
  }

  static LoadError _errorOf(ApiException e) {
    if (e.status == 401) return LoadError.signIn;
    if (e.status == 403 || e.status == 404 || e.code == 'not_found' || e.code == 'forbidden') {
      return LoadError.notFound;
    }
    return e.network ? LoadError.offline : LoadError.server;
  }
}
