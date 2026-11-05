part of 'explore_bloc.dart';

enum ExploreStatus {
  loading,
  success,

  /// There are no communities at all.
  none,
  failure,
}

final class ExploreState extends Equatable {
  const ExploreState({
    this.status = ExploreStatus.loading,
    this.page,
    this.counts = const {},
    this.realtime,
    this.error,
    this.showMap = false,
    this.selectedId,
  });

  final ExploreStatus status;
  final CommunityPage? page;

  /// Live spots per activity, from the first load's cards.
  final Map<String, LiveCount> counts;

  /// Null until the first load subscribes.
  final RealtimeStatus? realtime;
  final LoadError? error;
  final bool showMap;

  /// The map's chosen pin and preview card; see [selected].
  final String? selectedId;

  int spotsOf(ActivityCard a) => counts[a.id]?.spotsLeft ?? a.spotsLeft;
  bool changed(ActivityCard a) => counts[a.id]?.changed ?? false;
  bool get reconnecting => realtime == RealtimeStatus.reconnecting;

  /// Cards that can still be booked: the map shows only these, and the count line counts them.
  List<ActivityCard> get open => [
    for (final a in page?.activities ?? const <ActivityCard>[])
      if (a.status != ActivityCardStatusEnum.started && spotsOf(a) > 0) a,
  ];

  /// The map's selection: the chosen card while it's still open, else the first open one (it sold
  /// out or started live), or null with nothing open.
  ActivityCard? get selected {
    final cards = open;
    return cards.where((a) => a.id == selectedId).firstOrNull ?? cards.firstOrNull;
  }

  ExploreState copyWith({
    ExploreStatus? status,
    CommunityPage? page,
    Map<String, LiveCount>? counts,
    RealtimeStatus? realtime,
    LoadError? error,
    bool clearError = false,
    bool? showMap,
    String? selectedId,
  }) => ExploreState(
    status: status ?? this.status,
    page: page ?? this.page,
    counts: counts ?? this.counts,
    realtime: realtime ?? this.realtime,
    error: clearError ? null : error ?? this.error,
    showMap: showMap ?? this.showMap,
    selectedId: selectedId ?? this.selectedId,
  );

  @override
  List<Object?> get props => [status, page, counts, realtime, error, showMap, selectedId];
}
