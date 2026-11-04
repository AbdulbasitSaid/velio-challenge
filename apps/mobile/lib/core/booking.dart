// B1 booking outcomes (S7b FR-005), as apps/web/lib/booking.ts: the API's typed rejections become the
// designed states; only a server or network failure keeps the attempt's key for "Try again".
import 'api.dart';

enum BookingOutcome {
  /// Sold out mid-attempt: banner and next steps.
  soldOut,
  started,
  paused,

  /// The server view changed (already booked, removed, own activity): reload.
  refresh,
  signIn,

  /// Retry with the same key.
  error,
}

BookingOutcome bookingOutcome(Object err) => switch (ApiException.from(err).code) {
  'sold_out' => BookingOutcome.soldOut,
  'activity_started' => BookingOutcome.started,
  'bookings_paused' => BookingOutcome.paused,
  'already_booked' || 'booking_removed' || 'forbidden' => BookingOutcome.refresh,
  'unauthenticated' => BookingOutcome.signIn,
  _ => BookingOutcome.error,
};
