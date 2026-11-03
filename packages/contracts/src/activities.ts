import { z } from 'zod';

/** Where an activity happens (Google Maps spec FR-005). `lat`/`lng` are WGS 84 degrees. */
export const Location = z
  .object({
    placeId: z.string().trim().min(1).max(512).nullable().optional(),
    venueName: z.string().trim().min(1).max(200),
    addressText: z.string().trim().min(1).max(500),
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
    meetingPoint: z.string().trim().max(140).nullable().optional(),
  })
  .meta({ id: 'Location' });
export type Location = z.infer<typeof Location>;

/** ISO 8601 with an explicit offset, for example `2026-12-05T17:30:00+03:00`. */
const StartsAt = z.iso.datetime({ offset: true });

export const ActivityCreate = z
  .object({
    communitySlug: z.string().min(1).max(100),
    title: z.string().trim().min(1).max(200),
    description: z.string().max(5000).optional(),
    /** Must be in the future. */
    startsAt: StartsAt,
    /** IANA time zone, for example `Africa/Nairobi`. */
    timezone: z.string().min(1).max(64),
    location: Location,
    /** Price in minor units of `currency`. Shown, never charged (PRD non-goals). */
    priceMinor: z.number().int().positive().max(Number.MAX_SAFE_INTEGER),
    currency: z.string().regex(/^[A-Z]{3}$/),
    capacity: z.number().int().min(1).max(100_000),
  })
  .meta({ id: 'ActivityCreate' });
export type ActivityCreate = z.infer<typeof ActivityCreate>;

/**
 * Any subset of the editable fields. Date, time zone and location are locked once the activity
 * has a confirmed booking (`location_locked`). Capacity can't go below confirmed bookings
 * (`capacity_below_bookings`).
 */
export const ActivityPatch = z
  .object({
    title: ActivityCreate.shape.title,
    description: z.string().max(5000),
    startsAt: StartsAt,
    timezone: ActivityCreate.shape.timezone,
    location: Location,
    capacity: ActivityCreate.shape.capacity,
  })
  .partial()
  .meta({ id: 'ActivityPatch' });
export type ActivityPatch = z.infer<typeof ActivityPatch>;

/** Live availability. `version` increases with every committed change to `spotsLeft`. */
export const ActivityState = z
  .object({
    id: z.uuid(),
    spotsLeft: z.number().int(),
    version: z.number().int(),
  })
  .meta({ id: 'ActivityState' });
export type ActivityState = z.infer<typeof ActivityState>;

/** The activity as its host sees it. */
export const HostActivity = z
  .object({
    id: z.uuid(),
    hostId: z.uuid(),
    communitySlug: z.string(),
    title: z.string(),
    description: z.string(),
    startsAt: z.iso.datetime({ offset: true }),
    timezone: z.string(),
    location: Location,
    priceMinor: z.number().int(),
    currency: z.string(),
    capacity: z.number().int(),
    spotsLeft: z.number().int(),
    bookedCount: z.number().int(),
    version: z.number().int(),
    bookingsPaused: z.boolean(),
    createdAt: z.iso.datetime({ offset: true }),
  })
  .meta({ id: 'HostActivity' });
export type HostActivity = z.infer<typeof HostActivity>;
