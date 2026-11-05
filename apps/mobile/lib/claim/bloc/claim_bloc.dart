// G3 claim (S7 FR-010, FR-012, FR-016): one Idempotency-Key per attempt, kept for the code until a
// final outcome, so a retry or a restart during a slow claim never books twice. Nothing is queued
// (PRD M2).
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/invite_logic.dart';
import '../../repositories/invite_repository.dart';
import '../../repositories/session_repository.dart';

part 'claim_event.dart';
part 'claim_state.dart';

class ClaimBloc extends Bloc<ClaimEvent, ClaimState> {
  ClaimBloc({
    required InviteRepository inviteRepository,
    required SessionRepository sessionRepository,
    required this._code,
  }) : _invites = inviteRepository,
       _session = sessionRepository,
       // "Claiming as" needs the saved name; without it the guest fills the two fields.
       super(ClaimState(signedIn: sessionRepository.profile != null)) {
    on<ClaimRequested>(_onRequested);
    on<ClaimSubmitted>(_onSubmitted, transformer: droppable());
    on<ClaimNotYouPressed>(_onNotYouPressed, transformer: droppable());
  }

  final InviteRepository _invites;
  final SessionRepository _session;
  final String _code;

  Future<void> _onRequested(ClaimRequested event, Emitter<ClaimState> emit) async {
    final cached = await _invites.cachedInvite(_code);
    if (cached != null) emit(state.copyWith(view: cached.value));
    try {
      emit(state.copyWith(view: await _invites.invite(_code)));
    } catch (_) {
      // The cached copy is enough to show what's being claimed.
    }
  }

  Future<void> _onNotYouPressed(ClaimNotYouPressed event, Emitter<ClaimState> emit) async {
    if (state.submitting) return;
    await _session.signOut();
    emit(state.copyWith(signedIn: false));
  }

  Future<void> _onSubmitted(ClaimSubmitted event, Emitter<ClaimState> emit) async {
    final name = event.name.trim();
    final contact = event.contact.trim();
    final signedIn = state.signedIn;
    if (!signedIn && (name.isEmpty || contact.isEmpty)) {
      emit(
        state.copyWith(
          nameError: () => name.isEmpty ? nameError : null,
          contactError: () => contact.isEmpty ? contactError : null,
        ),
      );
      return;
    }
    emit(state.copyWith(submitting: true, nameError: () => null, contactError: () => null, banner: () => null));
    try {
      final res = await _invites.claim(_code, displayName: signedIn ? null : name, contact: signedIn ? null : contact);
      await _invites.clearAttempt(_code);
      final token = res.token;
      if (token != null) {
        await _session.adopt(token, userId: res.user.id, displayName: res.user.displayName, contact: contact);
      }
      emit(
        state.copyWith(submitting: false, result: ClaimResult.claimed, planId: res.planId, results: state.results + 1),
      );
    } on ApiException catch (e) {
      final outcome = claimOutcome(e.network ? null : e.code);
      if (outcome is! ClaimBanner || !outcome.retry) await _invites.clearAttempt(_code);
      final done = state.copyWith(submitting: false);
      emit(switch (outcome) {
        // Already booked from another device: the invite shows "You're already going" with the plan.
        ClaimDone() => done.copyWith(result: ClaimResult.alreadyGoing, results: state.results + 1),
        ClaimBack() => done.copyWith(result: ClaimResult.back, results: state.results + 1),
        ClaimFieldError(field: 'contact', :final message) => done.copyWith(contactError: () => message),
        ClaimFieldError(:final message) => done.copyWith(nameError: () => message),
        ClaimBanner() => done.copyWith(banner: () => outcome),
      });
    }
  }
}
