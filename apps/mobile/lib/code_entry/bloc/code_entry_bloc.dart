// G8 (S7 FR-004): checks a typed code before opening the invite, so an unknown code stays on this
// screen with the code kept (PRD Edge cases); a rate-limited device is told to wait (PRD R10).
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/api_exception.dart';
import '../../domain/format.dart';
import '../../repositories/invite_repository.dart';

part 'code_entry_event.dart';
part 'code_entry_state.dart';

class CodeEntryBloc extends Bloc<CodeEntryEvent, CodeEntryState> {
  /// [initialError] comes from an invite link that didn't resolve (`invalid` or `limited`).
  CodeEntryBloc({required InviteRepository inviteRepository, String? initialError})
    : _invites = inviteRepository,
      super(
        CodeEntryState(
          error: switch (initialError) {
            'invalid' => CodeEntryError.invalid,
            'limited' => CodeEntryError.limited,
            _ => null,
          },
        ),
      ) {
    on<CodeEntryChanged>(_onChanged);
    on<CodeEntrySubmitted>(_onSubmitted, transformer: droppable());
  }

  final InviteRepository _invites;

  void _onChanged(CodeEntryChanged event, Emitter<CodeEntryState> emit) =>
      emit(state.copyWith(code: () => normaliseCode(event.text), error: () => state.limited ? state.error : null));

  Future<void> _onSubmitted(CodeEntrySubmitted event, Emitter<CodeEntryState> emit) async {
    final code = state.code;
    if (code == null || state.limited) return;
    emit(state.copyWith(loading: true, error: () => null));
    try {
      await _invites.invite(code);
      emit(state.copyWith(loading: false, opened: code, opens: state.opens + 1));
    } on ApiException catch (e) {
      if (e.network) {
        // Offline: the invite screen shows the saved copy if it's this code, or says so.
        emit(state.copyWith(loading: false, opened: code, opens: state.opens + 1));
      } else {
        final limited = e.code == 'rate_limited';
        emit(state.copyWith(loading: false, error: () => limited ? CodeEntryError.limited : CodeEntryError.invalid));
      }
    }
  }
}
