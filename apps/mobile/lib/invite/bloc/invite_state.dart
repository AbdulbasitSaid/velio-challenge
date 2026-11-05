part of 'invite_bloc.dart';

/// Why the invite couldn't load: [invalid] and [limited] go back to code entry with the reason.
enum InviteError { offline, server, invalid, limited }

final class InviteState extends Equatable {
  const InviteState({
    this.view,
    this.cachedAt,
    this.offline = false,
    this.error,
    this.live,
    this.realtime = RealtimeStatus.connecting,
    this.next,
  });

  final InviteView? view;

  /// When the saved copy shown offline was fetched.
  final DateTime? cachedAt;

  /// The last request failed for want of a network.
  final bool offline;
  final InviteError? error;

  /// Live spots; null until the API's invite has loaded and the screen follows it.
  final LiveCount? live;
  final RealtimeStatus realtime;
  final NextSteps? next;

  int get spots => live?.spotsLeft ?? view?.activity.spotsLeft ?? 0;

  /// Which screen the invite shows at the live count.
  InviteScreen? get screen => view == null ? null : selectScreen(view!, spotsLeft: spots);

  InviteState copyWith({
    InviteView? view,
    DateTime? Function()? cachedAt,
    bool? offline,
    InviteError? Function()? error,
    LiveCount? live,
    RealtimeStatus? realtime,
    NextSteps? next,
  }) => InviteState(
    view: view ?? this.view,
    cachedAt: cachedAt != null ? cachedAt() : this.cachedAt,
    offline: offline ?? this.offline,
    error: error != null ? error() : this.error,
    live: live ?? this.live,
    realtime: realtime ?? this.realtime,
    next: next ?? this.next,
  );

  @override
  List<Object?> get props => [view, cachedAt, offline, error, live, realtime, next];
}
