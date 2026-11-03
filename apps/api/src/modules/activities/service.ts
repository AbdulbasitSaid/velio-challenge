import type { ActivityCreate, ActivityPatch, HostActivity, Location } from '@velio/contracts';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { changeCapacity, type Tx } from '../bookings/engine';

function locationColumns(location: Location) {
  return {
    place_id: location.placeId ?? null,
    venue_name: location.venueName,
    address_text: location.addressText,
    lat: location.lat,
    lng: location.lng,
    meeting_point: location.meetingPoint ?? null,
  };
}

function assertFuture(startsAt: string, now: Date) {
  if (new Date(startsAt) <= now) throw new ApiError('validation_failed', 'Invalid request: startsAt.');
}

async function loadHostActivity(db: Db | Tx, id: string): Promise<HostActivity> {
  const row = await db
    .selectFrom('activities')
    .innerJoin('communities', 'communities.id', 'activities.community_id')
    .selectAll('activities')
    .select('communities.slug')
    .where('activities.id', '=', id)
    .executeTakeFirstOrThrow();
  return {
    id: row.id,
    hostId: row.host_id,
    communitySlug: row.slug,
    title: row.title,
    description: row.description,
    startsAt: row.starts_at.toISOString(),
    timezone: row.timezone,
    location: {
      placeId: row.place_id,
      venueName: row.venue_name,
      addressText: row.address_text,
      lat: Number(row.lat),
      lng: Number(row.lng),
      meetingPoint: row.meeting_point,
    },
    priceMinor: Number(row.price_minor),
    currency: row.currency,
    capacity: row.capacity,
    spotsLeft: row.spots_left,
    bookedCount: row.capacity - row.spots_left,
    version: Number(row.version),
    bookingsPaused: row.bookings_paused,
    createdAt: row.created_at.toISOString(),
  };
}

/** PRD A1, A4. The photo is S5's (signed upload); `photo_key` stays null until then. */
export async function createActivity(
  db: Db,
  input: { hostId: string; body: ActivityCreate; now: Date },
): Promise<HostActivity> {
  const { body } = input;
  assertFuture(body.startsAt, input.now);
  const community = await db
    .selectFrom('communities')
    .select('id')
    .where('slug', '=', body.communitySlug)
    .executeTakeFirst();
  if (!community) throw new ApiError('not_found', 'Community not found.');

  const { id } = await db
    .insertInto('activities')
    .values({
      host_id: input.hostId,
      community_id: community.id,
      title: body.title,
      description: body.description ?? '',
      starts_at: body.startsAt,
      timezone: body.timezone,
      ...locationColumns(body.location),
      price_minor: body.priceMinor,
      currency: body.currency,
      capacity: body.capacity,
      spots_left: body.capacity,
    })
    .returning('id')
    .executeTakeFirstOrThrow();
  return loadHostActivity(db, id);
}

/**
 * Host-only edit in one transaction: a rejected part (location lock, capacity) leaves nothing
 * applied. Capacity goes through the booking engine, the only writer of spots_left.
 */
export async function updateActivity(
  db: Db,
  input: { activityId: string; userId: string; patch: ActivityPatch; now: Date },
): Promise<HostActivity> {
  const { patch, activityId } = input;
  if (patch.startsAt !== undefined) assertFuture(patch.startsAt, input.now);

  return db.transaction().execute(async (tx) => {
    // Locks the activity row first, like every booking write path.
    const current = await tx
      .selectFrom('activities')
      .select('host_id')
      .where('id', '=', activityId)
      .forUpdate()
      .executeTakeFirst();
    if (!current) throw new ApiError('not_found');
    if (current.host_id !== input.userId) throw new ApiError('forbidden');

    const fields = {
      ...(patch.title !== undefined && { title: patch.title }),
      ...(patch.description !== undefined && { description: patch.description }),
      ...(patch.startsAt !== undefined && { starts_at: patch.startsAt }),
      ...(patch.timezone !== undefined && { timezone: patch.timezone }),
      ...(patch.location !== undefined && locationColumns(patch.location)),
    };
    // The location-lock trigger raises VL001 (location_locked) here once someone has booked.
    if (Object.keys(fields).length > 0) {
      await tx.updateTable('activities').set(fields).where('id', '=', activityId).execute();
    }
    if (patch.capacity !== undefined) await changeCapacity(tx, activityId, patch.capacity);
    return loadHostActivity(tx, activityId);
  });
}
