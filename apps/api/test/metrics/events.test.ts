// S8 events (V: T3, T4): claim and failure events, and the client events endpoint.
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { testApp } from '../helpers/app';
import {
  book,
  bookOk,
  claim,
  createActivity,
  createInvite,
  errorCode,
  inProcess,
  newContact,
  signIn,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;
let request: Requester;

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db));
});

afterAll(async () => {
  await t.drop();
});

const events = (name: string, activityId: string) =>
  t.admin<{ user_id: string | null; rail: string | null; platform: string | null }[]>`
    SELECT user_id, rail, platform FROM events WHERE name = ${name} AND activity_id = ${activityId}`;

const post = (body: unknown, headers: Record<string, string> = {}, via: Requester = request) =>
  via('/api/events', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-device-id': randomUUID(), ...headers },
    body: JSON.stringify(body),
  });

describe('server events', () => {
  // FR-004, AC-003
  test('a claim writes exactly one invite_claimed', async () => {
    const host = await signIn(request, 'Amara Host');
    const tunde = await signIn(request, 'Tunde Booker');
    const a = await createActivity(request, host);
    const { booking } = await bookOk(request, tunde, a.id);
    const invite = await createInvite(request, tunde, booking.planId, { rail: 'public' });
    expect(
      (await claim(request, invite.code, { displayName: 'Kofi Guest', contact: newContact() })).status,
    ).toBe(201);
    const rows = await events('invite_claimed', a.id);
    expect(rows).toHaveLength(1);
    expect(rows[0]!.rail).toBe('public');
  });

  // FR-005
  test('a server error writes booking_failed; the response is still the error', async () => {
    const host = await signIn(request, 'Amara Host');
    const tunde = await signIn(request, 'Tunde Booker');
    const a = await createActivity(request, host);
    await t.admin.unsafe(`
      CREATE FUNCTION fail_booking() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN RAISE EXCEPTION 'injected failure'; END $$;
      CREATE TRIGGER fail_booking BEFORE INSERT ON bookings FOR EACH ROW
        WHEN (NEW.activity_id = '${a.id}') EXECUTE FUNCTION fail_booking();`);
    try {
      const res = await book(request, tunde, a.id);
      expect(res.status).toBe(500);
      expect(await errorCode(res)).toBe('internal');
      expect(await events('booking_failed', a.id)).toHaveLength(1);
    } finally {
      await t.admin.unsafe('DROP TRIGGER fail_booking ON bookings; DROP FUNCTION fail_booking();');
    }
  });
});

// FR-006, AC-004, SEC-003
describe('POST /api/events', () => {
  test('activity_viewed is stored with the session user; an unknown activity stores nothing', async () => {
    const host = await signIn(request, 'Amara Host');
    const viewer = await signIn(request, 'Kofi Viewer');
    const a = await createActivity(request, host);
    expect(
      (await post({ name: 'activity_viewed', activityId: a.id }, { ...viewer.headers, 'x-client': 'web' }))
        .status,
    ).toBe(204);
    expect((await post({ name: 'activity_viewed', activityId: randomUUID() })).status).toBe(204);
    expect([...(await events('activity_viewed', a.id))]).toEqual([
      { user_id: viewer.id, rail: null, platform: 'web' },
    ]);
  });

  test('web_vital is accepted and never stored', async () => {
    const before = await t.admin<{ n: number }[]>`SELECT count(*)::int AS n FROM events`;
    const res = await post({
      name: 'web_vital',
      metric: 'LCP',
      value: 1234,
      page: 'invite',
      connection: '3g',
    });
    expect(res.status).toBe(204);
    expect((await post({ name: 'web_vital', metric: 'CLS', value: 0.05, page: 'activity' })).status).toBe(
      204,
    );
    expect(await t.admin<{ n: number }[]>`SELECT count(*)::int AS n FROM events`).toEqual(before);
  });

  test('unknown names and bad payloads are 400', async () => {
    for (const body of [
      { name: 'booking_succeeded', activityId: randomUUID() },
      { name: 'web_vital', metric: 'FID', value: 1, page: 'invite' },
      { name: 'web_vital', metric: 'LCP', value: -1, page: 'invite' },
      { name: 'activity_viewed', activityId: 'nope' },
    ]) {
      const res = await post(body);
      expect(res.status).toBe(400);
      expect(await errorCode(res)).toBe('validation_failed');
    }
  });

  test('more than 60 a minute from one device is 429', async () => {
    // A fixed clock keeps all 61 requests in one window.
    const fixed = inProcess(testApp(t.db, () => new Date('2026-11-05T12:00:30Z')));
    const device = randomUUID();
    const body = { name: 'web_vital', metric: 'TTFB', value: 200, page: 'other' };
    for (let i = 0; i < 60; i++)
      expect((await post(body, { 'x-device-id': device }, fixed)).status).toBe(204);
    const res = await post(body, { 'x-device-id': device }, fixed);
    expect(res.status).toBe(429);
    expect(await errorCode(res)).toBe('rate_limited');
  });
});
