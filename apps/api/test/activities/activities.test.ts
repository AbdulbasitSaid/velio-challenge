import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { json, testApp } from '../helpers/app';
import {
  activityBody,
  book,
  createActivity,
  errorCode,
  inProcess,
  patchActivity,
  signIn,
  type Caller,
  type HostActivityBody,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;
let request: Requester;
let host: Caller;
let other: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db));
  host = await signIn(request, 'Amara Okafor');
  other = await signIn(request, 'Tunde Adeyemi');
});

afterAll(async () => {
  await t.drop();
});

async function activityRow(id: string) {
  const [row] =
    await t.admin`SELECT capacity, spots_left, version::int, title, starts_at, lat::float, meeting_point
                                FROM activities WHERE id = ${id}`;
  return row!;
}

describe('POST /api/activities', () => {
  // V-ACT-1 (FR-013)
  test('creates an activity owned by the caller with every spot open', async () => {
    const res = await request('/api/activities', json(activityBody({ capacity: 6 }), host.headers));
    expect(res.status).toBe(201);
    const body = (await res.json()) as HostActivityBody & Record<string, unknown>;
    expect(body.hostId).toBe(host.id);
    expect(body).toMatchObject({ capacity: 6, spotsLeft: 6, bookedCount: 0, version: 0 });
    expect(body.communitySlug).toBe('explore-kenya');
    expect(body.location).toMatchObject({ lat: -0.7667, meetingPoint: 'Meet at the blue gate by the jetty' });
    expect(body.priceMinor).toBe(350000);
    expect(body.bookingsPaused).toBe(false);
  });

  // V-ACT-2 (FR-013)
  test.each([
    ['past startsAt', { startsAt: new Date(Date.now() - 60_000).toISOString() }, 'validation_failed'],
    ['capacity 0', { capacity: 0 }, 'validation_failed'],
    ['bad currency', { currency: 'kes' }, 'validation_failed'],
    [
      '141-character meeting point',
      { location: { ...activityBody().location, meetingPoint: 'x'.repeat(141) } },
      'validation_failed',
    ],
    ['bad latitude', { location: { ...activityBody().location, lat: 91 } }, 'validation_failed'],
    ['invalid time zone', { timezone: 'Mars/Olympus_Mons' }, 'validation_failed'],
    ['unknown community', { communitySlug: 'nowhere' }, 'not_found'],
  ])('rejects %s and inserts nothing', async (_name, overrides, code) => {
    const [{ count: before }] = (await t.admin`SELECT count(*)::int FROM activities`) as [{ count: number }];
    const res = await request('/api/activities', json(activityBody(overrides), host.headers));
    expect(await errorCode(res)).toBe(code);
    expect(res.status).toBe(code === 'not_found' ? 404 : 400);
    const [{ count: after }] = (await t.admin`SELECT count(*)::int FROM activities`) as [{ count: number }];
    expect(after).toBe(before);
  });

  test('requires a session', async () => {
    const res = await request('/api/activities', json(activityBody()));
    expect(res.status).toBe(401);
    expect(await errorCode(res)).toBe('unauthenticated');
  });
});

describe('PATCH /api/activities/:id', () => {
  // V-ACT-3 (FR-014, SEC-001)
  test('the host edits title and description; another user is forbidden', async () => {
    const a = await createActivity(request, host);
    const res = await patchActivity(request, host, a.id, {
      title: 'Moonlight Kayaking',
      description: 'Later.',
    });
    expect(res.status).toBe(200);
    expect((await res.json()) as HostActivityBody).toMatchObject({
      title: 'Moonlight Kayaking',
      description: 'Later.',
    });

    const denied = await patchActivity(request, other, a.id, { title: 'Hijacked' });
    expect(denied.status).toBe(403);
    expect(await errorCode(denied)).toBe('forbidden');
    expect((await activityRow(a.id)).title).toBe('Moonlight Kayaking');
  });

  test('unknown activity → 404; no session → 401', async () => {
    const missing = await patchActivity(request, host, '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f', {
      title: 'x',
    });
    expect(missing.status).toBe(404);
    const anon = await request(`/api/activities/0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f`, {
      method: 'PATCH',
      headers: { 'content-type': 'application/json' },
      body: '{"title":"x"}',
    });
    expect(anon.status).toBe(401);
  });

  test('date, time zone and location can change before anyone books', async () => {
    const a = await createActivity(request, host);
    const startsAt = new Date(Date.now() + 40 * 86_400_000).toISOString();
    const res = await patchActivity(request, host, a.id, {
      startsAt,
      timezone: 'Africa/Dar_es_Salaam',
      location: { ...activityBody().location, lat: -1.5 },
    });
    expect(res.status).toBe(200);
    expect((await activityRow(a.id)).lat).toBe(-1.5);
  });

  // V-ACT-4 (FR-014)
  test('after a confirmed booking, date and location are locked; title still edits', async () => {
    const a = await createActivity(request, host);
    expect((await book(request, other, a.id)).status).toBe(201);
    const before = await activityRow(a.id);

    for (const patch of [
      { startsAt: new Date(Date.now() + 50 * 86_400_000).toISOString() },
      { location: { ...activityBody().location, lat: -1.5 } },
      { location: { ...activityBody().location, meetingPoint: 'By the kiosk' } },
      // Locked fields make the whole edit fail, including its unlocked parts.
      { title: 'Renamed', timezone: 'Africa/Dar_es_Salaam', capacity: 20 },
    ]) {
      const res = await patchActivity(request, host, a.id, patch);
      expect(res.status).toBe(409);
      expect(await errorCode(res)).toBe('location_locked');
      expect(await activityRow(a.id)).toEqual(before);
    }

    const ok = await patchActivity(request, host, a.id, { title: 'Renamed' });
    expect(ok.status).toBe(200);
    expect((await activityRow(a.id)).title).toBe('Renamed');
  });
});

describe('capacity', () => {
  async function soldOut(capacity: number) {
    const a = await createActivity(request, host, { capacity });
    for (let i = 0; i < capacity; i++) {
      const guest = await signIn(request, `Capacity Guest ${i}`);
      expect((await book(request, guest, a.id)).status).toBe(201);
    }
    return a;
  }

  // V-CAP-1 (FR-015)
  test('raising capacity on a sold-out activity reopens it', async () => {
    const a = await soldOut(2);
    const before = await activityRow(a.id);
    expect(before.spots_left).toBe(0);
    const res = await patchActivity(request, host, a.id, { capacity: 4 });
    expect(res.status).toBe(200);
    expect((await res.json()) as HostActivityBody).toMatchObject({
      capacity: 4,
      spotsLeft: 2,
      bookedCount: 2,
    });
    expect((await activityRow(a.id)).version).toBe(before.version + 1);
    expect((await book(request, other, a.id)).status).toBe(201);
  });

  // V-CAP-2 (AC-004)
  test('lowering below confirmed bookings fails and changes nothing', async () => {
    const a = await soldOut(3);
    const before = await activityRow(a.id);
    const res = await patchActivity(request, host, a.id, { capacity: 2 });
    expect(res.status).toBe(409);
    expect(await errorCode(res)).toBe('capacity_below_bookings');
    expect(await activityRow(a.id)).toEqual(before);
  });

  test('a rejected capacity also rolls back the other fields of the edit', async () => {
    const a = await soldOut(2);
    const res = await patchActivity(request, host, a.id, { title: 'Should not stick', capacity: 1 });
    expect(await errorCode(res)).toBe('capacity_below_bookings');
    expect((await activityRow(a.id)).title).toBe('Sunset Kayaking');
  });

  // V-CAP-3 (FR-015)
  test('lowering to exactly the confirmed count sells it out', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    await book(request, other, a.id);
    await book(request, await signIn(request, 'Zainab Bello'), a.id);
    const res = await patchActivity(request, host, a.id, { capacity: 2 });
    expect(res.status).toBe(200);
    expect(await activityRow(a.id)).toMatchObject({ capacity: 2, spots_left: 0 });
  });

  test('setting the current capacity is a no-op that keeps version', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    const before = await activityRow(a.id);
    const res = await patchActivity(request, host, a.id, { capacity: 5 });
    expect(res.status).toBe(200);
    expect(await activityRow(a.id)).toEqual(before);
  });

  test('capacity 0 is rejected by validation, even with no bookings', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    const before = await activityRow(a.id);
    const res = await patchActivity(request, host, a.id, { capacity: 0 });
    expect(res.status).toBe(400);
    expect(await errorCode(res)).toBe('validation_failed');
    expect(await activityRow(a.id)).toEqual(before);
  });

  test('a non-host cannot change capacity', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    const res = await patchActivity(request, other, a.id, { capacity: 50 });
    expect(res.status).toBe(403);
    expect((await activityRow(a.id)).capacity).toBe(5);
  });
});
