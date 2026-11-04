import type { ActivityCard, PublicActivity, PublicPerson } from '@velio/contracts';
import { sql } from 'kysely';
import type { Db } from '../../db/client';
import { toPublicPerson } from '../identity/people';

/** Avatar-stack size: an engineering choice, not a product rule (S3 PLANNING §12). */
export const MEMBER_PREVIEW = 8;

/** Google Maps URLs directions link (no key needed). */
export function directionsUrl(lat: number, lng: number, placeId: string | null): string {
  const url = new URL('https://www.google.com/maps/dir/');
  url.searchParams.set('api', '1');
  url.searchParams.set('destination', `${lat},${lng}`);
  if (placeId) url.searchParams.set('destination_place_id', placeId);
  return url.toString();
}

/**
 * The public snapshot (S3 FR-001). One query for the activity row, so `spotsLeft`, `version`,
 * `capacity` and `status` always agree (FR-002); one for members; one more for a signed-in viewer.
 * Started is decided by the database clock, as the booking engine does.
 */
export async function buildSnapshot(
  db: Db,
  activityId: string,
  viewerId: string | null,
): Promise<PublicActivity | undefined> {
  const row = await db
    .selectFrom('activities as a')
    .innerJoin('users as h', 'h.id', 'a.host_id')
    .innerJoin('communities as c', 'c.id', 'a.community_id')
    .select([
      'a.id',
      'a.title',
      'a.description',
      'a.photo_key',
      'a.starts_at',
      'a.timezone',
      'a.price_minor',
      'a.currency',
      'a.capacity',
      'a.spots_left',
      'a.version',
      'a.bookings_paused',
      'a.place_id',
      'a.venue_name',
      'a.address_text',
      'a.lat',
      'a.lng',
      'a.meeting_point',
      'h.id as host_id',
      'h.display_name as host_name',
      'c.slug as community_slug',
      'c.name as community_name',
      sql<boolean>`a.starts_at <= now()`.as('started'),
    ])
    .where('a.id', '=', activityId)
    .executeTakeFirst();
  if (!row) return undefined;

  // count(*) OVER () is computed before LIMIT, so it is the total even though few rows return.
  const members = await db
    .selectFrom('bookings as b')
    .innerJoin('users as u', 'u.id', 'b.user_id')
    .select(['u.id', 'u.display_name', sql<number>`count(*) OVER ()::int`.as('total')])
    .where('b.activity_id', '=', activityId)
    .where('b.status', '=', 'confirmed')
    .orderBy('b.created_at')
    .orderBy('b.id')
    .limit(MEMBER_PREVIEW)
    .execute();

  let viewer: PublicActivity['viewer'] = null;
  if (viewerId) {
    // A confirmed booking wins over an earlier removed one.
    const booking = await db
      .selectFrom('bookings')
      .select(['id', 'plan_id', 'status'])
      .where('activity_id', '=', activityId)
      .where('user_id', '=', viewerId)
      .orderBy(sql`status = 'confirmed'`, 'desc')
      .orderBy('created_at', 'desc')
      .executeTakeFirst();
    viewer = {
      isHost: row.host_id === viewerId,
      booking: booking
        ? {
            id: booking.id,
            planId: booking.plan_id,
            status: booking.status as 'confirmed' | 'removed',
          }
        : null,
    };
  }

  const lat = Number(row.lat);
  const lng = Number(row.lng);
  const preview: PublicPerson[] = members.map(toPublicPerson);
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    photoUrl: row.photo_key ? `/photos/${row.photo_key}` : null,
    startsAt: row.starts_at.toISOString(),
    timezone: row.timezone,
    priceMinor: Number(row.price_minor),
    currency: row.currency,
    capacity: row.capacity,
    spotsLeft: row.spots_left,
    version: Number(row.version),
    status: row.started ? 'started' : row.spots_left === 0 ? 'sold_out' : 'open',
    bookingsPaused: row.bookings_paused,
    host: toPublicPerson({ id: row.host_id, display_name: row.host_name }),
    community: { slug: row.community_slug, name: row.community_name },
    members: { count: members[0]?.total ?? 0, preview },
    location: {
      placeId: row.place_id,
      venueName: row.venue_name,
      addressText: row.address_text,
      lat,
      lng,
      meetingPoint: row.meeting_point,
      staticMapUrl: null,
      directionsUrl: directionsUrl(lat, lng, row.place_id),
    },
    viewer,
  };
}

/**
 * Cards for many activities in two queries, whatever the count (S4 §4.12, NFR-005): one for the
 * rows, one for every member preview. Returned in the order of `ids`; unknown IDs are skipped.
 */
export async function buildCards(db: Db, ids: string[]): Promise<ActivityCard[]> {
  if (ids.length === 0) return [];
  const rows = await db
    .selectFrom('activities as a')
    .innerJoin('communities as c', 'c.id', 'a.community_id')
    .select([
      'a.id',
      'a.title',
      'a.starts_at',
      'a.timezone',
      'a.price_minor',
      'a.currency',
      'a.photo_key',
      'a.capacity',
      'a.spots_left',
      'a.version',
      'a.venue_name',
      'a.lat',
      'a.lng',
      'c.slug as community_slug',
      'c.name as community_name',
      sql<boolean>`a.starts_at <= now()`.as('started'),
    ])
    .where('a.id', 'in', ids)
    .execute();
  const members = await db
    .selectFrom((eb) =>
      eb
        .selectFrom('bookings as b')
        .innerJoin('users as u', 'u.id', 'b.user_id')
        .select([
          'b.activity_id',
          'u.id',
          'u.display_name',
          sql<number>`row_number() OVER (PARTITION BY b.activity_id ORDER BY b.created_at, b.id)::int`.as(
            'n',
          ),
          sql<number>`count(*) OVER (PARTITION BY b.activity_id)::int`.as('total'),
        ])
        .where('b.activity_id', 'in', ids)
        .where('b.status', '=', 'confirmed')
        .as('m'),
    )
    .selectAll()
    .where('m.n', '<=', MEMBER_PREVIEW)
    .orderBy('m.n')
    .execute();
  const byActivity = new Map<string, { count: number; preview: PublicPerson[] }>();
  for (const m of members) {
    const entry = byActivity.get(m.activity_id) ?? { count: m.total, preview: [] };
    entry.preview.push(toPublicPerson(m));
    byActivity.set(m.activity_id, entry);
  }
  const cards = new Map(
    rows.map((r): [string, ActivityCard] => [
      r.id,
      {
        id: r.id,
        title: r.title,
        startsAt: r.starts_at.toISOString(),
        timezone: r.timezone,
        priceMinor: Number(r.price_minor),
        currency: r.currency,
        photoUrl: r.photo_key ? `/photos/${r.photo_key}` : null,
        capacity: r.capacity,
        spotsLeft: r.spots_left,
        version: Number(r.version),
        status: r.started ? 'started' : r.spots_left === 0 ? 'sold_out' : 'open',
        community: { slug: r.community_slug, name: r.community_name },
        location: { venueName: r.venue_name, lat: Number(r.lat), lng: Number(r.lng) },
        members: byActivity.get(r.id) ?? { count: 0, preview: [] },
      },
    ]),
  );
  return ids.flatMap((id) => cards.get(id) ?? []);
}
