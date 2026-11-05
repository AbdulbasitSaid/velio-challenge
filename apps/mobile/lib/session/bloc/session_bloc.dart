// Who is signed in, for the whole app (S7 FR-017): follows SessionRepository's changes.
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../repositories/session_repository.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required SessionRepository sessionRepository})
    : _session = sessionRepository,
      super(SessionState(sessionRepository.profile)) {
    on<SessionSubscriptionRequested>(_onSubscriptionRequested);
  }

  final SessionRepository _session;

  Future<void> _onSubscriptionRequested(SessionSubscriptionRequested event, Emitter<SessionState> emit) =>
      emit.forEach(_session.changes, onData: SessionState.new);
}
