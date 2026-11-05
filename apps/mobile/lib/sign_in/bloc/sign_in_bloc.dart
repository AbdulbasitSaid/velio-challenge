// X1 sign in (S7 FR-017, PRD Q14): name and the phone or email used before, so My plans works on a
// new phone. Only app paths are accepted as where to go next.
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/api_exception.dart';
import '../../domain/invite_logic.dart';
import '../../repositories/session_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({required SessionRepository sessionRepository, this._next})
    : _session = sessionRepository,
      super(const SignInState()) {
    on<SignInSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SessionRepository _session;
  final String? _next;

  Future<void> _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    final name = event.name.trim();
    final contact = event.contact.trim();
    emit(SignInState(nameError: name.isEmpty ? nameError : null, contactError: contact.isEmpty ? contactError : null));
    if (name.isEmpty || contact.isEmpty) return;
    emit(const SignInState(busy: true));
    try {
      await _session.signIn(name, contact);
      final next = _next;
      emit(
        SignInState(destination: next != null && next.startsWith('/') && !next.startsWith('//') ? next : '/me/plans'),
      );
    } on ApiException catch (e) {
      emit(switch (e.code) {
        'invalid_contact' => const SignInState(
          contactError: 'Enter a phone number with country code, or a full email address.',
        ),
        'validation_failed' => const SignInState(nameError: nameError),
        _ => SignInState(error: e.network ? 'Check your connection and try again.' : 'We couldn’t sign you in.'),
      });
    }
  }
}
