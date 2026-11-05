// "Invite a friend" (S7 FR-013): a vouch for one named friend, or the Plan's public link, with resume
// for a link its creator paused. The contact goes only to the API, never into the message.
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/format.dart';
import '../../repositories/plan_repository.dart';

part 'invite_sheet_event.dart';
part 'invite_sheet_state.dart';

class InviteSheetBloc extends Bloc<InviteSheetEvent, InviteSheetState> {
  InviteSheetBloc({required PlanRepository planRepository, required this._plan, required this._activity})
    : _plans = planRepository,
      super(const InviteSheetState()) {
    on<InviteSheetVouchChosen>((event, emit) => emit(state.copyWith(step: InviteSheetStep.vouch)));
    on<InviteSheetVouchSubmitted>(_onVouchSubmitted, transformer: droppable());
    on<InviteSheetLinkRequested>(_onLinkRequested, transformer: droppable());
    on<InviteSheetResumePressed>(_onResumePressed, transformer: droppable());
  }

  final PlanRepository _plans;
  final PlanView _plan;
  final PublicActivity _activity;

  Future<void> _onVouchSubmitted(InviteSheetVouchSubmitted event, Emitter<InviteSheetState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(nameError: () => 'Add their name, so the invite is addressed to them.'));
      return;
    }
    emit(state.copyWith(busy: true, nameError: () => null, contactError: () => null, error: () => null));
    final contact = event.contact.trim();
    final note = event.note.trim();
    try {
      final inv = await _plans.createInvite(_plan.id, {
        'rail': 'vouch',
        'inviteeName': name,
        'contact': contact.isEmpty ? null : contact,
        'note': note.isEmpty ? null : note,
      });
      final a = _activity;
      emit(state.copyWith(busy: false, message: () => vouchMessage(name, a.title, a.startsAt, a.timezone, inv.link)));
    } on ApiException catch (e) {
      emit(
        e.code == 'invalid_contact'
            ? state.copyWith(
                busy: false,
                contactError: () => 'Enter a full phone number with country code, or an email address.',
              )
            : state.copyWith(
                busy: false,
                error: () => e.network ? 'Check your connection and try again.' : 'We couldn’t create the invite.',
              ),
      );
    }
  }

  Future<void> _onLinkRequested(InviteSheetLinkRequested event, Emitter<InviteSheetState> emit) => _openLink(emit);

  Future<void> _openLink(Emitter<InviteSheetState> emit) async {
    emit(state.copyWith(step: InviteSheetStep.link, busy: true, error: () => null));
    try {
      // Returns the caller's existing public link (S5 T12).
      final inv = await _plans.createInvite(_plan.id, {'rail': 'public'});
      emit(state.copyWith(busy: false, link: () => inv));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          busy: false,
          error: () => e.network ? 'Check your connection and try again.' : 'We couldn’t get your link.',
        ),
      );
    }
  }

  Future<void> _onResumePressed(InviteSheetResumePressed event, Emitter<InviteSheetState> emit) async {
    final l = state.link;
    if (l == null) return;
    emit(state.copyWith(busy: true));
    try {
      await _plans.resumeInvite(l.code);
    } on ApiException {
      emit(state.copyWith(busy: false, error: () => 'We couldn’t resume the link.'));
      return;
    }
    await _openLink(emit);
  }
}
