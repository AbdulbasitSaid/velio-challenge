// H1 attendance (S7b FR-011, FR-012), ported from apps/web/lib/attendance.ts: row labels, guest search,
// ordering and the counts the screen shows. Pure, so the screen stays a thin view over them.
import 'package:velio_api/velio_api.dart';

import 'api.dart';
import 'format.dart';

/// "Direct", "Via Tunde" or "Public link" (PRD H1).
String attendeeSource(Attendee a) => switch (a.source_) {
  AttendeeSource_Enum.vouch => a.invitedBy != null ? 'Via ${firstName(a.invitedBy!.displayName)}' : 'Vouch',
  AttendeeSource_Enum.public => 'Public link',
  AttendeeSource_Enum.direct => 'Direct',
};

String _compact(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// Phone check-in: a name fragment, or a booking ref with or without "VLO-", any case.
bool matchesGuest(Attendee a, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (a.person.displayName.toLowerCase().contains(q)) return true;
  final ref = _compact(query);
  return ref.length >= 2 &&
      _compact(a.ref).replaceFirst(RegExp('^vlo'), '').contains(ref.replaceFirst(RegExp('^vlo'), ''));
}

/// Before the start the newest booking leads ("Newest first"); after it the list is a check-in sheet in
/// booking order, so rows don't move while the host marks. Removed bookings go last either way.
List<Attendee> orderAttendees(List<Attendee> attendees, {required bool started}) => [...attendees]
  ..sort((x, y) {
    if (x.status != y.status) return x.status == AttendeeStatusEnum.confirmed ? -1 : 1;
    var by = x.bookedAt.compareTo(y.bookedAt);
    if (by == 0) by = x.bookingId.compareTo(y.bookingId);
    return started ? by : -by;
  });

class AttendanceStats {
  const AttendanceStats({
    required this.booked,
    required this.capacity,
    required this.throughInvites,
    required this.marked,
    required this.attended,
    required this.noShows,
  });
  final int booked;
  final int capacity;
  final int throughInvites;
  final int marked;
  final int attended;
  final int noShows;
}

AttendanceStats attendanceStats(Attendance data) {
  final confirmed = data.attendees.where((a) => a.status == AttendeeStatusEnum.confirmed).toList();
  return AttendanceStats(
    booked: confirmed.length,
    capacity: data.activity.capacity,
    throughInvites: confirmed.where((a) => a.source_ != AttendeeSource_Enum.direct).length,
    marked: confirmed.where((a) => a.mark != null).length,
    attended: confirmed.where((a) => a.mark == AttendanceMark.attended).length,
    noShows: confirmed.where((a) => a.mark == AttendanceMark.noShow).length,
  );
}

/// Text for a failed mark.
String markFailure(Object err, String name) {
  final e = ApiException.from(err);
  if (e.code == 'booking_removed') return '${firstName(name)} was removed, so they can’t be marked.';
  if (e.code == 'activity_not_started') return 'You can mark attendance once the activity starts.';
  if (e.network) return 'You’re offline. Reconnect to mark attendance.';
  return 'We couldn’t save that mark. Try again.';
}
