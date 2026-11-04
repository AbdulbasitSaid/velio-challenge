import type { Attendance, Attendee, HostActivityList } from '@velio/contracts';
import { sql } from 'kysely';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { buildCards } from '../activities/snapshot';
import { toMemberPerson } from '../identity/people';
import { notifyAttendance } from '../realtime/notify';

type Mark = 'attended' | 'no_show';

export function createAttendanceService(db: Db) {
  /** Confirmed and removed bookings with source, inviter and latest mark; never contacts or notes. */
  function attendeeQuery(activityId: string) {
    return db
      .selectFrom('bookings as b')
      .innerJoin('users as u', 'u.id', 'b.user_id')
      .leftJoin('invites as i', 'i.id', 'b.invite_id')
      .leftJoin('users as inv', 'inv.id', 'i.inviter_id')
      .leftJoinLateral(
        (eb) =>
          eb
            .selectFrom('attendance_marks as am')
            .select(['am.mark', 'am.created_at'])
            .whereRef('am.booking_id', '=', 'b.id')
            .orderBy('am.created_at', 'desc')
            .orderBy('am.id', 'desc')
            .limit(1)
            .as('m'),
        (join) => join.onTrue(),
      )
      .select([
        'b.id',
        'b.ref',
        'b.status',
        'b.source',
        'b.plan_id',
        'b.created_at',
        'u.id as user_id',
        'u.display_name',
        'inv.id as inviter_id',
        'inv.display_name as inviter_name',
        'm.mark',
        'm.created_at as marked_at',
      ])
      .where('b.activity_id', '=', activityId)
      .orderBy('b.created_at')
      .orderBy('b.id');
  }

  type Row = Awaited<ReturnType<ReturnType<typeof attendeeQuery>['execute']>>[number];

  const toAttendee = (r: Row): Attendee => ({
    bookingId: r.id,
    ref: r.ref,
    status: r.status as Attendee['status'],
    person: toMemberPerson({ id: r.user_id, display_name: r.display_name }),
    bookedAt: r.created_at.toISOString(),
    source: r.source as Attendee['source'],
    invitedBy:
      r.inviter_id && r.inviter_name
        ? toMemberPerson({ id: r.inviter_id, display_name: r.inviter_name })
        : null,
    planId: r.plan_id,
    mark: (r.mark as Mark | null) ?? null,
    markedAt: r.marked_at ? r.marked_at.toISOString() : null,
  });

  async function hostActivity(activityId: string, hostId: string) {
    const a = await db
      .selectFrom('activities')
      .select([
        'id',
        'host_id',
        'capacity',
        'spots_left',
        'version',
        'starts_at',
        'timezone',
        sql<boolean>`starts_at <= now()`.as('started'),
      ])
      .where('id', '=', activityId)
      .executeTakeFirst();
    if (!a) throw new ApiError('not_found');
    if (a.host_id !== hostId) throw new ApiError('forbidden');
    return a;
  }

  /** PRD H1, D5 (S4 FR-024). */
  async function list(activityId: string, hostId: string): Promise<Attendance> {
    const a = await hostActivity(activityId, hostId);
    const rows = await attendeeQuery(activityId).execute();
    return {
      activity: {
        id: a.id,
        capacity: a.capacity,
        spotsLeft: a.spots_left,
        version: Number(a.version),
        startsAt: a.starts_at.toISOString(),
        timezone: a.timezone,
        started: a.started,
      },
      attendees: rows.map(toAttendee),
    };
  }

  /** PRD H2 (S4 FR-025): after start, on confirmed bookings; insert-only, the latest mark wins. */
  async function mark(bookingId: string, hostId: string, mark: Mark): Promise<Attendee> {
    const booking = await db
      .selectFrom('bookings')
      .select(['activity_id', 'status'])
      .where('id', '=', bookingId)
      .executeTakeFirst();
    if (!booking) throw new ApiError('not_found');
    const a = await hostActivity(booking.activity_id, hostId);
    if (!a.started) throw new ApiError('activity_not_started');
    if (booking.status !== 'confirmed') throw new ApiError('booking_removed');
    await db.transaction().execute(async (tx) => {
      await tx
        .insertInto('attendance_marks')
        .values({ booking_id: bookingId, mark, marked_by: hostId })
        .execute();
      await notifyAttendance(tx, booking.activity_id);
    });
    const row = await attendeeQuery(booking.activity_id)
      .where('b.id', '=', bookingId)
      .executeTakeFirstOrThrow();
    return toAttendee(row);
  }

  /** The H3 screen (S4 FR-023): the caller's hosted activities, upcoming soonest first. */
  async function hosted(hostId: string): Promise<HostActivityList> {
    const rows = await db
      .selectFrom('activities')
      .select(['id', 'capacity', 'spots_left', sql<boolean>`starts_at <= now()`.as('past')])
      .where('host_id', '=', hostId)
      .orderBy('starts_at')
      .execute();
    const cards = new Map(
      (
        await buildCards(
          db,
          rows.map((r) => r.id),
        )
      ).map((c) => [c.id, c]),
    );
    const toItem = (r: (typeof rows)[number]) => ({
      ...cards.get(r.id)!,
      bookedCount: r.capacity - r.spots_left,
    });
    return {
      upcoming: rows.filter((r) => !r.past).map(toItem),
      past: rows
        .filter((r) => r.past)
        .reverse()
        .map(toItem),
    };
  }

  return { list, mark, hosted };
}

export type AttendanceService = ReturnType<typeof createAttendanceService>;
