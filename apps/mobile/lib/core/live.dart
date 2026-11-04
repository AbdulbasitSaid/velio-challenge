// Live spots for one screen (S7 FR-008): follows `activity:<id>` (and the Plan's topic), applies the
// version gate (rule 2), announces changes politely at most once every 5 s (UX NFR-003) and acks
// each painted version (rule 6).
import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'format.dart';
import 'realtime.dart';

class LiveSpots extends ChangeNotifier {
  LiveSpots({
    required this.realtime,
    required this.activityId,
    required int spotsLeft,
    required int version,
    required this.refresh,
    this.planId,
    this.onPlan,
    this.view,
    this.announceEvery = const Duration(seconds: 5),
  }) : _spots = spotsLeft,
       _shownVersion = version {
    _statusSub = realtime.statusChanges.listen((_) => notifyListeners());
    _stop = realtime.watch(
      Watch(
        topics: ['activity:$activityId', if (planId != null) 'plan:$planId'],
        refresh: refresh,
        onSpots: (e) => apply(e.spotsLeft, e.version, fromEvent: true),
        onPlan: onPlan == null ? null : (_) => onPlan!(),
      ),
    );
  }

  final RealtimeClient realtime;
  final String activityId;
  final String? planId;

  /// Fetches the screen's snapshots and passes the activity's count to [apply].
  final Future<void> Function() refresh;
  final void Function()? onPlan;

  /// For announcements; null in tests without a view.
  final FlutterView? view;
  final Duration announceEvery;

  int _spots;
  int _shownVersion;
  bool _changed = false;
  DateTime? _lastAnnounced;
  Timer? _pendingAnnounce;
  late final StreamSubscription<RealtimeStatus> _statusSub;
  late final void Function() _stop;

  int get spotsLeft => _spots;
  int get version => _shownVersion;

  /// A live change just landed (the lime flash, UX FR-003).
  bool get changed => _changed;
  RealtimeStatus get status => realtime.status;

  /// Rule 2: only a newer version is shown.
  void apply(int spotsLeft, int version, {bool fromEvent = false}) {
    if (version <= _shownVersion) return;
    final moved = spotsLeft != _spots;
    _spots = spotsLeft;
    _shownVersion = version;
    _changed = fromEvent && moved;
    notifyListeners();
    if (fromEvent) {
      if (moved) _announce();
      final v = version;
      SchedulerBinding.instance.addPostFrameCallback((_) => realtime.rendered(activityId, v));
    }
  }

  void _announce() {
    final now = DateTime.now();
    final last = _lastAnnounced;
    if (last == null || now.difference(last) >= announceEvery) {
      _say();
    } else {
      _pendingAnnounce?.cancel();
      _pendingAnnounce = Timer(announceEvery - now.difference(last), _say);
    }
  }

  void _say() {
    _lastAnnounced = DateTime.now();
    final v = view;
    if (v != null) {
      SemanticsService.sendAnnouncement(v, spotsLabel(_spots), TextDirection.ltr, assertiveness: Assertiveness.polite);
    }
  }

  @override
  void dispose() {
    _pendingAnnounce?.cancel();
    _statusSub.cancel();
    _stop();
    super.dispose();
  }
}
