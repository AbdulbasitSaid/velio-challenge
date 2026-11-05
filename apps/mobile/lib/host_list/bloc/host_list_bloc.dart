// H3 My activities (S7b FR-006): the host's upcoming and past activities, reloaded when who's signed
// in changes.
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';
import '../../repositories/session_repository.dart';

part 'host_list_event.dart';
part 'host_list_state.dart';

class HostListBloc extends Bloc<HostListEvent, HostListState> {
  HostListBloc({required HostRepository hostRepository, required SessionRepository sessionRepository})
    : _host = hostRepository,
      _session = sessionRepository,
      super(HostListState(signedIn: sessionRepository.signedIn)) {
    on<HostListRequested>(_onRequested);
    on<HostListSessionSubscriptionRequested>(_onSessionSubscriptionRequested);
    on<HostListSessionChanged>(_onSessionChanged);
    on<HostListPastToggled>((event, emit) => emit(state.copyWith(past: event.past)));
  }

  final HostRepository _host;
  final SessionRepository _session;

  Future<void> _onRequested(HostListRequested event, Emitter<HostListState> emit) async {
    try {
      await _load(emit);
    } finally {
      event.done?.complete();
    }
  }

  Future<void> _load(Emitter<HostListState> emit) async {
    if (!_session.signedIn) return;
    try {
      final data = await _host.hostActivities();
      emit(state.copyWith(data: () => data, error: () => null));
    } on ApiException catch (e) {
      emit(state.copyWith(error: () => e.status == 401 ? LoadError.signIn : LoadError.of(e)));
    }
  }

  Future<void> _onSessionSubscriptionRequested(
    HostListSessionSubscriptionRequested event,
    Emitter<HostListState> emit,
  ) => emit.onEach(_session.changes, onData: (_) => add(const HostListSessionChanged()));

  /// Signing in or out: the list belongs to someone else now.
  Future<void> _onSessionChanged(HostListSessionChanged event, Emitter<HostListState> emit) async {
    emit(state.copyWith(signedIn: _session.signedIn, data: () => null));
    await _load(emit);
  }
}
