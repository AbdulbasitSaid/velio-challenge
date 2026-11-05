// B6 My plans (S7 FR-014, FR-015): the saved list first, then the API's; the saved list offline. Reloads
// when someone signs in or out.
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/load_error.dart';
import '../../repositories/plan_repository.dart';
import '../../repositories/session_repository.dart';

part 'my_plans_event.dart';
part 'my_plans_state.dart';

class MyPlansBloc extends Bloc<MyPlansEvent, MyPlansState> {
  MyPlansBloc({required PlanRepository planRepository, required SessionRepository sessionRepository})
    : _plans = planRepository,
      _session = sessionRepository,
      super(MyPlansState(signedIn: sessionRepository.signedIn)) {
    on<MyPlansSubscriptionRequested>(_onSubscriptionRequested);
    on<MyPlansRequested>(_onRequested);
    on<MyPlansTabChanged>((event, emit) => emit(state.copyWith(past: event.past)));
  }

  final PlanRepository _plans;
  final SessionRepository _session;

  Future<void> _onSubscriptionRequested(MyPlansSubscriptionRequested event, Emitter<MyPlansState> emit) =>
      emit.onEach(_session.changes, onData: (_) => add(const MyPlansRequested(reset: true)));

  Future<void> _onRequested(MyPlansRequested event, Emitter<MyPlansState> emit) async {
    final signedIn = _session.signedIn;
    emit(
      event.reset
          ? MyPlansState(signedIn: signedIn, past: state.past, loading: true)
          : state.copyWith(signedIn: signedIn, loading: true),
    );
    if (!signedIn) {
      emit(state.copyWith(loading: false));
      return;
    }
    final cached = await _plans.cachedMyPlans();
    if (cached != null && state.plans == null) emit(state.copyWith(plans: () => cached.value));
    try {
      final plans = await _plans.myPlans();
      emit(state.copyWith(plans: () => plans, offline: false, error: () => null, loading: false));
    } on ApiException catch (e) {
      if (e.network && cached != null) {
        emit(state.copyWith(offline: true, cachedAt: () => cached.fetchedAt, loading: false));
      } else {
        emit(state.copyWith(error: () => e.status == 401 ? LoadError.signIn : LoadError.of(e), loading: false));
      }
    }
  }
}
