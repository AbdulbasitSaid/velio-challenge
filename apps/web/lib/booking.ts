// B1 booking outcomes (S5 FR-024, FR-025). The API's typed rejections become the designed states; only
// a server or network failure keeps the attempt's key for "Try again".
import { ApiRequestError } from './api/client';

export type BookingOutcome =
  | { kind: 'sold-out' } // sold out mid-checkout: banner and next steps
  | { kind: 'started' }
  | { kind: 'paused' }
  | { kind: 'refresh' } // the server view changed (already booked, removed, own activity)
  | { kind: 'signin' }
  | { kind: 'error' }; // B5: retry with the same key

export function bookingOutcome(err: unknown): BookingOutcome {
  if (!(err instanceof ApiRequestError)) return { kind: 'error' };
  switch (err.code) {
    case 'sold_out':
      return { kind: 'sold-out' };
    case 'activity_started':
      return { kind: 'started' };
    case 'bookings_paused':
      return { kind: 'paused' };
    case 'already_booked':
    case 'booking_removed':
    case 'forbidden':
      return { kind: 'refresh' };
    case 'unauthenticated':
      return { kind: 'signin' };
    default:
      return { kind: 'error' };
  }
}

export const bookingScope = (activityId: string) => `book_${activityId}`;
