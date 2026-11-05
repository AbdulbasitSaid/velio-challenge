import type { ErrorCode, ErrorEnvelope } from '@velio/contracts';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

const STATUS: Record<ErrorCode, ContentfulStatusCode> = {
  sold_out: 409,
  already_booked: 409,
  already_claimed: 409,
  invite_expired: 410,
  invite_paused: 409,
  activity_started: 409,
  bookings_paused: 409,
  invalid_code: 404,
  rate_limited: 429,
  idempotency_conflict: 409,
  booking_removed: 409,
  activity_not_started: 409,
  location_locked: 409,
  capacity_below_bookings: 409,
  invites_unavailable: 403,
  invalid_contact: 400,
  validation_failed: 400,
  unauthenticated: 401,
  forbidden: 403,
  not_found: 404,
  internal: 500,
};

const DEFAULT_MESSAGE: Partial<Record<ErrorCode, string>> = {
  unauthenticated: 'Sign in to continue.',
  forbidden: 'Not allowed.',
  not_found: 'Not found.',
  internal: 'Something went wrong.',
  sold_out: 'No spots left.',
  already_booked: 'You already have a spot on this activity.',
  activity_started: 'This activity has already started.',
  bookings_paused: 'Bookings are paused for this activity.',
  idempotency_conflict: 'This Idempotency-Key was already used for another activity.',
  booking_removed: 'The host removed your booking for this activity.',
  activity_not_started: 'Attendance can be marked once the activity has started.',
  invalid_code: "We can't find that invite.",
  already_claimed: 'This invite has already been claimed.',
  invite_expired: 'This invite expired when the activity started.',
  invite_paused: 'This link is paused.',
  rate_limited: 'Too many attempts from this device. Try again in an hour.',
  location_locked: 'Date, time zone and location are locked once someone has booked.',
  capacity_below_bookings: 'Capacity cannot go below the number of confirmed bookings.',
  invites_unavailable: 'Invites aren’t available on your account.',
};

/** A typed API error. Thrown anywhere; `app.onError` turns it into the envelope. */
export class ApiError extends Error {
  readonly status: ContentfulStatusCode;

  constructor(
    readonly code: ErrorCode,
    message?: string,
  ) {
    super(message ?? DEFAULT_MESSAGE[code] ?? code);
    this.status = STATUS[code];
  }
}

/** Postgres SQLSTATEs raised by our triggers (see migrations) that map to API codes. */
const PG_CODES: Record<string, ErrorCode> = {
  VL001: 'location_locked',
  VL004: 'validation_failed',
};

export function fromPostgresError(err: unknown): ApiError | undefined {
  const code = (err as { code?: unknown } | null)?.code;
  if (typeof code !== 'string') return undefined;
  const apiCode = PG_CODES[code];
  if (apiCode === 'validation_failed') return new ApiError(apiCode, 'Invalid request: timezone.');
  return apiCode ? new ApiError(apiCode) : undefined;
}

export function envelope(err: ApiError, requestId: string): ErrorEnvelope {
  return { error: { code: err.code, message: err.message, requestId } };
}
