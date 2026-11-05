//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ErrorCode {
  @JsonValue(r'sold_out')
  soldOut(r'sold_out'),
  @JsonValue(r'already_booked')
  alreadyBooked(r'already_booked'),
  @JsonValue(r'already_claimed')
  alreadyClaimed(r'already_claimed'),
  @JsonValue(r'invite_expired')
  inviteExpired(r'invite_expired'),
  @JsonValue(r'invite_paused')
  invitePaused(r'invite_paused'),
  @JsonValue(r'activity_started')
  activityStarted(r'activity_started'),
  @JsonValue(r'bookings_paused')
  bookingsPaused(r'bookings_paused'),
  @JsonValue(r'invalid_code')
  invalidCode(r'invalid_code'),
  @JsonValue(r'rate_limited')
  rateLimited(r'rate_limited'),
  @JsonValue(r'idempotency_conflict')
  idempotencyConflict(r'idempotency_conflict'),
  @JsonValue(r'booking_removed')
  bookingRemoved(r'booking_removed'),
  @JsonValue(r'activity_not_started')
  activityNotStarted(r'activity_not_started'),
  @JsonValue(r'location_locked')
  locationLocked(r'location_locked'),
  @JsonValue(r'capacity_below_bookings')
  capacityBelowBookings(r'capacity_below_bookings'),
  @JsonValue(r'invites_unavailable')
  invitesUnavailable(r'invites_unavailable'),
  @JsonValue(r'invalid_contact')
  invalidContact(r'invalid_contact'),
  @JsonValue(r'validation_failed')
  validationFailed(r'validation_failed'),
  @JsonValue(r'unauthenticated')
  unauthenticated(r'unauthenticated'),
  @JsonValue(r'forbidden')
  forbidden(r'forbidden'),
  @JsonValue(r'not_found')
  notFound(r'not_found'),
  @JsonValue(r'internal')
  internal(r'internal');

  const ErrorCode(this.value);

  final String value;

  @override
  String toString() => value;
}
