// H1 attendance (S5 FR-035–FR-038): row labels, the groups summary (UX-3), guest search and the stats
// the canvas shows. Pure, so the screen stays a thin view over them.
import type { Attendance, Attendee } from '@velio/contracts';
import { firstName } from './format';

/** "Direct", "Via Tunde" or "Public link" (PRD H1). */
export function attendeeSource(a: Attendee): string {
  if (a.source === 'vouch') return a.invitedBy ? `Via ${firstName(a.invitedBy.displayName)}` : 'Vouch';
  return a.source === 'public' ? 'Public link' : 'Direct';
}

export interface Group {
  planId: string;
  label: string;
  count: number;
}

/**
 * People who came in through each other's invites: one group per Plan with two or more confirmed
 * bookings, named after the Plan's first booking; single bookings add up to "Booked alone".
 */
export function groupsSummary(attendees: Attendee[]): { groups: Group[]; alone: number } {
  const plans = new Map<string, { first: Attendee; count: number }>();
  for (const a of attendees) {
    const p = plans.get(a.planId);
    if (!p) plans.set(a.planId, { first: a, count: 0 });
    else if (a.bookedAt < p.first.bookedAt) p.first = a;
  }
  for (const a of attendees) if (a.status === 'confirmed') plans.get(a.planId)!.count++;
  const groups: Group[] = [];
  let alone = 0;
  for (const [planId, p] of plans) {
    if (p.count >= 2)
      groups.push({ planId, label: `${firstName(p.first.person.displayName)}'s group`, count: p.count });
    else alone += p.count;
  }
  groups.sort((x, y) => y.count - x.count || x.label.localeCompare(y.label));
  return { groups, alone };
}

const compact = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, '');

/** Phone check-in (FR-038): a name fragment, or a booking ref with or without "VLO-", any case. */
export function matchesGuest(a: Attendee, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  if (a.person.displayName.toLowerCase().includes(q)) return true;
  const ref = compact(query);
  return ref.length >= 2 && compact(a.ref).replace(/^vlo/, '').includes(ref.replace(/^vlo/, ''));
}

/**
 * Before the start the newest booking leads ("Newest first"); after it the list is a check-in sheet in
 * booking order, so rows don't move while the host marks. Removed bookings go last either way.
 */
export function orderAttendees(attendees: Attendee[], started: boolean): Attendee[] {
  return [...attendees].sort((x, y) => {
    if (x.status !== y.status) return x.status === 'confirmed' ? -1 : 1;
    const by = x.bookedAt.localeCompare(y.bookedAt) || x.bookingId.localeCompare(y.bookingId);
    return started ? by : -by;
  });
}

export interface AttendanceStats {
  booked: number;
  capacity: number;
  throughInvites: number;
  marked: number;
  attended: number;
  noShows: number;
}

export function attendanceStats(data: Attendance): AttendanceStats {
  const confirmed = data.attendees.filter((a) => a.status === 'confirmed');
  return {
    booked: confirmed.length,
    capacity: data.activity.capacity,
    throughInvites: confirmed.filter((a) => a.source !== 'direct').length,
    marked: confirmed.filter((a) => a.mark).length,
    attended: confirmed.filter((a) => a.mark === 'attended').length,
    noShows: confirmed.filter((a) => a.mark === 'no_show').length,
  };
}
