import { z } from 'zod';

/**
 * Every error code the API can return. Later specs use these codes; they do not add ad-hoc strings.
 * Domain codes come from the MVP plan §4.4 and the Google Maps spec; the rest are generic.
 */
export const ERROR_CODES = [
  // Booking and invites (MVP plan §4.4)
  'sold_out',
  'already_booked',
  'already_claimed',
  'invite_expired',
  'invite_paused',
  'activity_started',
  'bookings_paused',
  'invalid_code',
  'rate_limited',
  // Booking engine (S2)
  'idempotency_conflict',
  'booking_removed',
  // Attendance (S4)
  'activity_not_started',
  // Activity edits (Google Maps spec)
  'location_locked',
  'capacity_below_bookings',
  // Holdout (S8): invite tools are withheld from this user
  'invites_unavailable',
  // Generic
  'invalid_contact',
  'validation_failed',
  'unauthenticated',
  'forbidden',
  'not_found',
  'internal',
] as const;

export const ErrorCode = z.enum(ERROR_CODES).meta({ id: 'ErrorCode' });
export type ErrorCode = z.infer<typeof ErrorCode>;

export const ErrorEnvelope = z
  .object({
    error: z.object({
      code: ErrorCode,
      message: z.string(),
      requestId: z.string(),
    }),
  })
  .meta({ id: 'ErrorEnvelope' });
export type ErrorEnvelope = z.infer<typeof ErrorEnvelope>;
