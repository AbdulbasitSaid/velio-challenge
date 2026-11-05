// Live updates for blocs (S7 FR-008, S7b FR-011): one app-wide socket, watched per screen as a stream
// that ends the watch when the bloc cancels it. Version gating is the bloc's (see domain/live.dart).
import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../data/realtime.dart';

export '../data/realtime.dart' show RealtimeStatus;

sealed class LiveUpdate {
  const LiveUpdate();
}

/// A `spots` event for one of the watched activities.
final class LiveSpotsChanged extends LiveUpdate {
  const LiveSpotsChanged(this.activityId, this.spotsLeft, this.version);
  final String activityId;
  final int spotsLeft;
  final int version;
}

/// Fetch every snapshot again: after subscribe (rule 1), on resync (rule 4), and every 10 s while
/// disconnected (rule 3).
final class LiveRefreshRequested extends LiveUpdate {
  const LiveRefreshRequested();
}

/// Rule 5: the Plan changed.
final class LivePlanChanged extends LiveUpdate {
  const LivePlanChanged(this.planId);
  final String planId;
}

/// Rule 5: a booking on the host's activity changed.
final class LiveAttendanceChanged extends LiveUpdate {
  const LiveAttendanceChanged(this.activityId);
  final String activityId;
}

final class LiveStatusChanged extends LiveUpdate {
  const LiveStatusChanged(this.status);
  final RealtimeStatus status;
}

class LiveRepository {
  LiveRepository(this._realtime);
  final RealtimeClient _realtime;

  RealtimeStatus get status => _realtime.status;

  /// Follows [topics] (`activity:<id>`, `plan:<id>`, `host:<id>`) while the stream is listened to.
  Stream<LiveUpdate> watch(List<String> topics) {
    late final StreamController<LiveUpdate> controller;
    StreamSubscription<RealtimeStatus>? statusSub;
    void Function()? stop;
    void add(LiveUpdate u) {
      if (!controller.isClosed) controller.add(u);
    }

    controller = StreamController<LiveUpdate>(
      onListen: () {
        statusSub = _realtime.statusChanges.listen((s) => add(LiveStatusChanged(s)));
        stop = _realtime.watch(
          Watch(
            topics: topics,
            refresh: () async => add(const LiveRefreshRequested()),
            onSpots: (e) => add(LiveSpotsChanged(e.activityId, e.spotsLeft, e.version)),
            onPlan: (id) => add(LivePlanChanged(id)),
            onAttendance: (id) => add(LiveAttendanceChanged(id)),
          ),
        );
      },
      onCancel: () {
        statusSub?.cancel();
        stop?.call();
      },
    );
    return controller.stream;
  }

  /// Rule 6: acknowledges a `spots` version once the frame showing it is painted.
  void rendered(String activityId, int version) =>
      SchedulerBinding.instance.addPostFrameCallback((_) => _realtime.rendered(activityId, version));

  /// App lifecycle: the socket closes in the background and resumes with a refetch (S7 FR-008).
  void setForeground(bool foreground) => _realtime.setForeground(foreground);

  /// Sign-in or sign-out: reconnect so `plan:` and `host:` topics follow the new session.
  void reconnect() => _realtime.reconnect();
}
