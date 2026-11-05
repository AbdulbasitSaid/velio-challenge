// The invite (S7 FR-006, FR-007, FR-009, FR-015): the saved copy first on a revisit and whenever the
// phone is offline, then the API's with live spots under the realtime rules, the open beacon once,
// and next steps when the invite can't be claimed.
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/invite_logic.dart';
import '../../domain/live.dart';
import '../../repositories/invite_repository.dart';
import '../../repositories/live_repository.dart';

part 'invite_event.dart';
part 'invite_state.dart';

class InviteBloc extends Bloc<InviteEvent, InviteState> {
  InviteBloc({required InviteRepository inviteRepository, required LiveRepository liveRepository, required this._code})
    : _invites = inviteRepository,
      _live = liveRepository,
      super(const InviteState()) {
    on<InviteRequested>(_onRequested);
    on<InviteLiveUpdated>(_onLiveUpdated, transformer: sequential());
    on<InviteShown>(_onShown);
    on<InviteNextStepsRequested>(_onNextStepsRequested);
  }

  final InviteRepository _invites;
  final LiveRepository _live;
  final String _code;
  bool _watching = false;
  bool _opened = false;
  bool _nextRequested = false;

  Future<void> _onRequested(InviteRequested event, Emitter<InviteState> emit) async {
    emit(state.copyWith(error: () => null));
    final cached = await _invites.cachedInvite(_code);
    if (cached != null && state.view == null) emit(state.copyWith(view: cached.value));
    try {
      await _fetch(emit);
    } on ApiException catch (e) {
      if (e.network && cached != null) {
        emit(state.copyWith(offline: true, cachedAt: () => cached.fetchedAt));
      } else {
        emit(state.copyWith(error: () => _errorOf(e)));
      }
      return;
    }
    if (_watching) return;
    _watching = true;
    final id = state.view!.activity.id;
    emit(state.copyWith(realtime: _live.status));
    await emit.onEach(_live.watch(['activity:$id']), onData: (u) => add(InviteLiveUpdated(u)));
  }

  Future<void> _fetch(Emitter<InviteState> emit) async {
    final view = await _invites.invite(_code);
    final a = view.activity;
    final current = state.live;
    final live = current == null
        ? LiveCount(spotsLeft: a.spotsLeft, version: a.version)
        : current.apply(a.spotsLeft, a.version) ?? current;
    emit(state.copyWith(view: view, offline: false, error: () => null, live: live));
  }

  Future<void> _onLiveUpdated(InviteLiveUpdated event, Emitter<InviteState> emit) async {
    switch (event.update) {
      case LiveSpotsChanged(:final activityId, :final spotsLeft, :final version):
        final next = state.live?.apply(spotsLeft, version, fromEvent: true);
        if (next == null) return;
        emit(state.copyWith(live: next));
        _live.rendered(activityId, version);
      case LiveRefreshRequested():
        try {
          await _fetch(emit);
        } on ApiException catch (e) {
          if (e.network) emit(state.copyWith(offline: true));
        }
      case LiveStatusChanged(:final status):
        emit(state.copyWith(realtime: status));
      case LivePlanChanged() || LiveAttendanceChanged():
        break;
    }
  }

  /// FR-009: once, after the first frame of the live invite.
  Future<void> _onShown(InviteShown event, Emitter<InviteState> emit) async {
    if (_opened) return;
    _opened = true;
    await _invites.open(_code);
  }

  Future<void> _onNextStepsRequested(InviteNextStepsRequested event, Emitter<InviteState> emit) async {
    try {
      emit(state.copyWith(next: await _invites.nextSteps(event.activityId)));
    } catch (_) {
      // Next steps are extras (UX FR-007).
    }
  }

  /// Next steps load once the invite can't be claimed (G5, G6, G7, paused).
  @override
  void onChange(Change<InviteState> change) {
    super.onChange(change);
    final s = change.nextState;
    final screen = s.screen;
    if (!_nextRequested && screen != null && screen is! OpenScreen) {
      _nextRequested = true;
      add(InviteNextStepsRequested(s.view!.activity.id));
    }
  }

  static InviteError _errorOf(ApiException e) {
    if (e.network) return InviteError.offline;
    if (e.code == 'rate_limited') return InviteError.limited;
    if (e.code == 'invalid_code' || e.code == 'not_found') return InviteError.invalid;
    return InviteError.server;
  }
}
