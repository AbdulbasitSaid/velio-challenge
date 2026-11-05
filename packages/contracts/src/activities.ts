import { z } from 'zod';
import { PublicPerson } from './people';
import { PhotoKey } from './uploads';

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
    /** From `POST /uploads/photos`, uploaded by the caller. */
    photoKey: PhotoKey.optional(),
  })
  .meta({ id: 'ActivityCreate' });
export type ActivityCreate = z.infer<typeof ActivityCreate>;

/**
 * Any subset of the editable fields. Date, time zone and location are locked once the activity
 * has a confirmed booking (`location_locked`). Capacity can't go below confirmed bookings
 * (`capacity_below_bookings`). The photo stays editable; `photoKey: null` removes it.
 */
export const ActivityPatch = z
  .object({
    title: ActivityCreate.shape.title,
    description: z.string().max(5000),
    startsAt: StartsAt,
    timezone: ActivityCreate.shape.timezone,
    location: Location,
    capacity: ActivityCreate.shape.capacity,
    photoKey: PhotoKey.nullable(),
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
    photoKey: PhotoKey.nullable(),
    createdAt: z.iso.datetime({ offset: true }),
  })
  .meta({ id: 'HostActivity' });
export type HostActivity = z.infer<typeof HostActivity>;

/** The activity's place as public screens show it (Maps spec FR-014). */
export const PublicLocation = Location.extend({
  placeId: z.string().nullable(),
  meetingPoint: z.string().nullable(),
  /** Signed Static Maps image. Null until signing is configured (S6); clients show the address instead (PRD A7). */
  staticMapUrl: z.string().nullable(),
  /** Google Maps directions to the pin. */
  directionsUrl: z.string(),
}).meta({ id: 'PublicLocation' });
export type PublicLocation = z.infer<typeof PublicLocation>;

/**
 * The public activity snapshot (S3). Clients start, reconnect and poll from it; `spotsLeft` and
 * `version` come from one read, so live `spots` events with a higher version replace them.
 */
export const PublicActivity = z
  .object({
    id: z.uuid(),
    title: z.string(),
    description: z.string(),
    /** `/photos/<key>` on the app's origin (CloudFront in production), or null without a photo. */
    photoUrl: z.string().nullable(),
    startsAt: z.iso.datetime({ offset: true }),
    timezone: z.string(),
    priceMinor: z.number().int(),
    currency: z.string(),
    capacity: z.number().int(),
    spotsLeft: z.number().int(),
    version: z.number().int(),
    /** `started` wins over `sold_out`. */
    status: z.enum(['open', 'sold_out', 'started']),
    bookingsPaused: z.boolean(),
    host: PublicPerson,
    community: z.object({ slug: z.string(), name: z.string() }),
    /** Confirmed bookings; `preview` is the earliest few, for the avatar stack. */
    members: z.object({ count: z.number().int(), preview: z.array(PublicPerson) }),
    location: PublicLocation,
    /** The signed-in caller's relation to the activity; null when signed out. */
    viewer: z
      .object({
        isHost: z.boolean(),
        booking: z
          .object({ id: z.uuid(), planId: z.uuid(), status: z.enum(['confirmed', 'removed']) })
          .nullable(),
      })
      .nullable(),
  })
  .meta({ id: 'PublicActivity' });
export type PublicActivity = z.infer<typeof PublicActivity>;

/** An activity in a list (community page, My plans, profile, next-steps). Public data only. */
export const ActivityCard = z
  .object({
    id: z.uuid(),
    title: z.string(),
    /** The description's start: whitespace collapsed, cut at a word to at most 140 characters plus `…`; `''` without one. */
    summary: z.string(),
    startsAt: z.iso.datetime({ offset: true }),
    timezone: z.string(),
    priceMinor: z.number().int(),
    currency: z.string(),
    photoUrl: z.string().nullable(),
    capacity: z.number().int(),
    spotsLeft: z.number().int(),
    version: z.number().int(),
    status: PublicActivity.shape.status,
    community: PublicActivity.shape.community,
    location: z.object({ venueName: z.string(), lat: z.number(), lng: z.number() }),
    members: PublicActivity.shape.members,
  })
  .meta({ id: 'ActivityCard' });
export type ActivityCard = z.infer<typeof ActivityCard>;
