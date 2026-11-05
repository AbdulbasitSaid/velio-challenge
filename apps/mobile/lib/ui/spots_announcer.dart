// The polite screen-reader announcement of a live spots change (UX NFR-003): at most once every 5 s,
// with the latest count said when the wait ends.
import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../domain/format.dart';
import '../domain/live.dart';

class SpotsAnnouncer extends StatefulWidget {
  const SpotsAnnouncer({super.key, required this.count, required this.child, this.every = const Duration(seconds: 5)});

  /// Announced when a new count arrives with `changed` set (a live event moved it).
  final LiveCount? count;
  final Widget child;
  final Duration every;

  @override
  State<SpotsAnnouncer> createState() => _SpotsAnnouncerState();
}

class _SpotsAnnouncerState extends State<SpotsAnnouncer> {
  DateTime? _lastAnnounced;
  Timer? _pending;

  @override
  void didUpdateWidget(SpotsAnnouncer old) {
    super.didUpdateWidget(old);
    final count = widget.count;
    if (count != null && count.changed && count != old.count) _announce();
  }

  void _announce() {
    final now = DateTime.now();
    final last = _lastAnnounced;
    if (last == null || now.difference(last) >= widget.every) {
      _say();
    } else {
      _pending?.cancel();
      _pending = Timer(widget.every - now.difference(last), _say);
    }
  }

  void _say() {
    final count = widget.count;
    if (!mounted || count == null) return;
    _lastAnnounced = DateTime.now();
    final view = View.maybeOf(context);
    if (view != null) {
      SemanticsService.sendAnnouncement(
        view,
        spotsLabel(count.spotsLeft),
        TextDirection.ltr,
        assertiveness: Assertiveness.polite,
      );
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
