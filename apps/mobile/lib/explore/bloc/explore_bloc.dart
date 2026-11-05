// C1 community (S7b FR-003): loads the community (the first one on the Explore tab) and keeps every
// card's spots live, with the version gate per activity (rule 2).
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/live.dart';
import '../../domain/load_error.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/live_repository.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({required ActivityRepository activityRepository, required LiveRepository liveRepository, String? slug})
    : _activities = activityRepository,
      _live = liveRepository,
      _requestedSlug = slug,
      super(const ExploreState()) {
    on<ExploreRequested>(_onRequested);
    on<ExploreLiveSubscriptionRequested>(_onLiveSubscriptionRequested);
    on<ExploreLiveUpdated>(_onLiveUpdated);
    on<ExploreViewToggled>((event, emit) => emit(state.copyWith(showMap: event.showMap)));
    on<ExploreMapSelected>((event, emit) => emit(state.copyWith(selectedId: event.activityId)));
  }

  final ActivityRepository _activities;
  final LiveRepository _live;

  /// Null on the Explore tab: the first community, as web `/` does.
  final String? _requestedSlug;

  Future<void> _onRequested(ExploreRequested event, Emitter<ExploreState> emit) async {
    // Try again from the error screen shows the skeleton.
    if (state.status == ExploreStatus.failure) emit(state.copyWith(status: ExploreStatus.loading, clearError: true));
    try {
      var slug = _requestedSlug;
      if (slug == null) {
        final list = await _activities.communities();
        if (list.communities.isEmpty) {
          emit(state.copyWith(status: ExploreStatus.none));
          return;
        }
        slug = list.communities.first.slug;
      }
      final page = await _activities.community(slug);
      final first = state.counts.isEmpty;
      emit(
        state.copyWith(
          status: ExploreStatus.success,
          page: page,
          counts: first
              ? {for (final a in page.activities) a.id: LiveCount(spotsLeft: a.spotsLeft, version: a.version)}
              : _applied(page),
          clearError: true,
        ),
      );
      if (first) add(const ExploreLiveSubscriptionRequested());
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: state.page == null ? ExploreStatus.failure : state.status,
          error: LoadError.of(e, notFound: const {404, 400}),
        ),
      );
    } finally {
      event.done?.complete();
    }
  }

  /// Snapshot counts through the version gate.
  Map<String, LiveCount> _applied(CommunityPage page) {
    final counts = {...state.counts};
    for (final a in page.activities) {
      final next = counts[a.id]?.apply(a.spotsLeft, a.version);
      if (next != null) counts[a.id] = next;
    }
    return counts;
  }

  Future<void> _onLiveSubscriptionRequested(ExploreLiveSubscriptionRequested event, Emitter<ExploreState> emit) {
    emit(state.copyWith(realtime: _live.status));
    return emit.onEach(
      _live.watch([for (final id in state.counts.keys) 'activity:$id']),
      onData: (update) => add(ExploreLiveUpdated(update)),
    );
  }

  Future<void> _onLiveUpdated(ExploreLiveUpdated event, Emitter<ExploreState> emit) async {
    switch (event.update) {
      case LiveSpotsChanged(:final activityId, :final spotsLeft, :final version):
        final next = state.counts[activityId]?.apply(spotsLeft, version, fromEvent: true);
        if (next == null) return;
        emit(state.copyWith(counts: {...state.counts, activityId: next}));
        _live.rendered(activityId, version);
      case LiveStatusChanged(:final status):
        emit(state.copyWith(realtime: status));
      case LiveRefreshRequested():
        final slug = state.page?.community.slug;
        if (slug == null) return;
        try {
          final page = await _activities.community(slug);
          emit(state.copyWith(counts: _applied(page)));
        } on ApiException {
          // The realtime client keeps polling while disconnected.
        }
      case LivePlanChanged() || LiveAttendanceChanged():
        break;
    }
  }
}
