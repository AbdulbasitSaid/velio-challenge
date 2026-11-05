// Live spots as values (S7 FR-008; realtime rules in packages/contracts/src/realtime.ts). Rule 2: only
// a newer version is shown.
import 'package:equatable/equatable.dart';

class LiveCount extends Equatable {
  const LiveCount({required this.spotsLeft, required this.version, this.changed = false});

  final int spotsLeft;
  final int version;

  /// A live change just moved the count (the lime flash, UX FR-003).
  final bool changed;

  /// The count after a snapshot or an event, or null when [version] isn't newer (rule 2).
  LiveCount? apply(int spotsLeft, int version, {bool fromEvent = false}) {
    if (version <= this.version) return null;
    return LiveCount(spotsLeft: spotsLeft, version: version, changed: fromEvent && spotsLeft != this.spotsLeft);
  }

  @override
  List<Object> get props => [spotsLeft, version, changed];
}
