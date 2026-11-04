import { describe, expect, test } from 'bun:test';
import { z } from 'zod';
import {
  ActivityCard,
  Attendance,
  Booking,
  BookingResponse,
  ClientMessage,
  ERROR_CODES,
  ClaimResponse,
  CommunityPage,
  HostActivity,
  Invite,
  InviteView,
  MemberPerson,
  MyPlans,
  NextSteps,
  PlanView,
  Profile,
  PublicActivity,
  PublicPerson,
  ServerMessage,
  Topic,
} from '../src';

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

  // S3 V-CON-1 (SEC-001): the public snapshot names people only as PublicPerson and carries no
  // contact, code, note or booking reference.
  test('PublicActivity exposes no full names, contacts, codes, notes or refs', () => {
    const keys = JSON.stringify(z.toJSONSchema(PublicActivity));
    expect(keys).not.toMatch(/displayName|contact|hash|email|phone|code|note|"ref"|token/i);
    expect(PublicActivity.shape.host).toBe(PublicPerson);
  });

  test('realtime topics and messages', () => {
    const id = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
    for (const t of [`activity:${id}`, `plan:${id}`, `host:${id}`])
      expect(Topic.safeParse(t).success).toBe(true);
    for (const t of [`user:${id}`, 'activity:x', `activity:${id.toUpperCase()}`])
      expect(Topic.safeParse(t).success).toBe(false);
    expect(ClientMessage.safeParse({ type: 'subscribe', topics: [] }).success).toBe(false);
    expect(ClientMessage.safeParse({ type: 'rendered', activityId: id, version: 3 }).success).toBe(true);
    expect(ServerMessage.safeParse({ type: 'plan', planId: id }).success).toBe(true);
    expect(ServerMessage.safeParse({ type: 'plan', planId: id, displayName: 'x' }).data).toEqual({
      type: 'plan',
      planId: id,
    });
  });

  // S4 V-CON-1 (SEC-001–SEC-003): no contact or hash fields anywhere; the public invite view carries
  // no invitee name; public lists name people only as PublicPerson.
  test('S4 schemas expose no contacts or hashes', () => {
    for (const schema of [
      Invite,
      InviteView,
      ClaimResponse,
      PlanView,
      MyPlans,
      Attendance,
      CommunityPage,
      Profile,
      NextSteps,
    ]) {
      expect(JSON.stringify(z.toJSONSchema(schema))).not.toMatch(/contact|hash|email|phone/i);
    }
    expect(Object.keys(InviteView.shape)).not.toContain('inviteeName');
    for (const schema of [ActivityCard, CommunityPage, Profile, NextSteps, InviteView]) {
      expect(JSON.stringify(z.toJSONSchema(schema))).not.toContain('displayName');
    }
    expect(Object.keys(Attendance.shape.attendees.element.shape)).not.toContain('note');
  });
});
