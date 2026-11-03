import { describe, expect, test } from 'bun:test';
import { Booking, BookingResponse, ERROR_CODES, HostActivity, MemberPerson, PublicPerson } from '../src';

describe('contracts', () => {
  // V-CON-2 (SEC-005): public responses can never carry a full name.
  test('PublicPerson has no displayName', () => {
    expect(Object.keys(PublicPerson.shape)).not.toContain('displayName');
  });

  test('PublicPerson strips a displayName passed to it', () => {
    const parsed = PublicPerson.parse({
      id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f',
      shortName: 'Tunde A.',
      avatarSeed: 'seed',
      displayName: 'Tunde Adeyemi',
    });
    expect(parsed).not.toHaveProperty('displayName');
  });

  test('MemberPerson adds displayName', () => {
    expect(Object.keys(MemberPerson.shape)).toContain('displayName');
  });

  test('error codes include location_locked and internal', () => {
    expect(ERROR_CODES).toContain('location_locked');
    expect(ERROR_CODES).toContain('internal');
  });

  test('error codes include the S2 booking codes', () => {
    for (const code of ['idempotency_conflict', 'capacity_below_bookings', 'booking_removed'] as const)
      expect(ERROR_CODES).toContain(code);
  });

  // S2 V-CON-2 (SEC-003): booking and host responses carry no contact or hash fields.
  test('Booking, BookingResponse and HostActivity expose no contact, hash or key fields', () => {
    const keys = [
      ...Object.keys(Booking.shape),
      ...Object.keys(BookingResponse.shape),
      ...Object.keys(BookingResponse.shape.activity.shape),
      ...Object.keys(HostActivity.shape),
    ];
    for (const key of keys) expect(key).not.toMatch(/contact|hash|email|phone|idempotency|token/i);
    expect(Object.keys(Booking.shape).sort()).toEqual(
      ['activityId', 'createdAt', 'id', 'planId', 'ref', 'source', 'status'].sort(),
    );
  });
});
