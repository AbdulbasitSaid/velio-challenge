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
  location_locked: 409,
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
};

export function fromPostgresError(err: unknown): ApiError | undefined {
  const code = (err as { code?: unknown } | null)?.code;
  if (typeof code !== 'string') return undefined;
  const apiCode = PG_CODES[code];
  return apiCode ? new ApiError(apiCode) : undefined;
}

export function envelope(err: ApiError, requestId: string): ErrorEnvelope {
  return { error: { code: err.code, message: err.message, requestId } };
}
