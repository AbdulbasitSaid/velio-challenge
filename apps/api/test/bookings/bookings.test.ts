import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { testApp } from '../helpers/app';
import {
  book,
  createActivity,
  errorCode,
  inProcess,
  removeBooking,
  signIn,
  type BookingBody,
  type Caller,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

const UNKNOWN_ID = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';

let t: TestDatabase;
let request: Requester;
let host: Caller;
let tunde: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db));
  host = await signIn(request, 'Amara Okafor');
  tunde = await signIn(request, 'Tunde Adeyemi');
});

afterAll(async () => {
  await t.drop();
});

async function state(activityId: string) {
  const [row] = await t.admin`
    SELECT spots_left, version::int,
           (SELECT count(*)::int FROM bookings WHERE activity_id = a.id) AS bookings,
           (SELECT count(*)::int FROM plans WHERE activity_id = a.id) AS plans
      FROM activities a WHERE id = ${activityId}`;
  return row as { spots_left: number; version: number; bookings: number; plans: number };
}

async function rejectionReasons(userId: string) {
  const rows = await t.admin<{ reason: string; activity_id: string | null }[]>`
    SELECT props->>'reason' AS reason, activity_id FROM events
     WHERE name = 'booking_rejected' AND user_id = ${userId} ORDER BY id`;
  return rows.map((r) => ({ reason: r.reason, activityId: r.activity_id }));
}

describe('POST /api/activities/:id/bookings', () => {
  // V-BK-1 (FR-001, FR-006, FR-008)
  test('books one spot and creates a Plan owned by the booker', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    const res = await book(request, tunde, a.id);
    expect(res.status).toBe(201);
    const body = (await res.json()) as BookingBody;
    expect(Object.keys(body.booking).sort()).toEqual(
      ['activityId', 'createdAt', 'id', 'planId', 'ref', 'source', 'status'].sort(),
    );
    expect(body.booking).toMatchObject({ activityId: a.id, source: 'direct', status: 'confirmed' });
    expect(body.booking.ref).toMatch(/^VLO-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$/);
    expect(body.activity).toEqual({ id: a.id, spotsLeft: 2, version: 1 });

    const [plan] = await t.admin`SELECT owner_id, activity_id FROM plans WHERE id = ${body.booking.planId}`;
    expect(plan).toEqual({ owner_id: tunde.id, activity_id: a.id });
    expect(await state(a.id)).toEqual({ spots_left: 2, version: 1, bookings: 1, plans: 1 });

    // V-BK-9 (FR-016): success recorded in the transaction.
    const [event] = await t.admin`
      SELECT user_id, generation, rail FROM events WHERE name = 'booking_succeeded' AND activity_id = ${a.id}`;
    expect(event).toEqual({ user_id: tunde.id, generation: 0, rail: null });
  });

  // V-BK-2 (FR-002), V-BK-9
  test('typed rejections change nothing', async () => {
    const a = await createActivity(request, host);
    const guest = await signIn(request, 'Rejected Guest');
    const before = await state(a.id);

    const unknown = await book(request, guest, UNKNOWN_ID);
    expect([unknown.status, await errorCode(unknown)]).toEqual([404, 'not_found']);

    const own = await book(request, host, a.id);
    expect([own.status, await errorCode(own)]).toEqual([403, 'forbidden']);

    const missingKey = await request(`/api/activities/${a.id}/bookings`, {
      method: 'POST',
      headers: guest.headers,
    });
    expect([missingKey.status, await errorCode(missingKey)]).toEqual([400, 'validation_failed']);

    const badKey = await book(request, guest, a.id, 'has spaces and !');
    expect([badKey.status, await errorCode(badKey)]).toEqual([400, 'validation_failed']);

    const anon = await request(`/api/activities/${a.id}/bookings`, {
      method: 'POST',
      headers: { 'idempotency-key': randomUUID() },
    });
    expect([anon.status, await errorCode(anon)]).toEqual([401, 'unauthenticated']);

    expect(await state(a.id)).toEqual(before);
    expect(await rejectionReasons(guest.id)).toEqual([{ reason: 'not_found', activityId: null }]);
    expect(await rejectionReasons(host.id)).toEqual([{ reason: 'forbidden', activityId: a.id }]);
  });

  // V-BK-5 (FR-005)
  test('a second booking with a new key is already_booked and takes no spot', async () => {
    const a = await createActivity(request, host);
    const guest = await signIn(request, 'Double Booker');
    expect((await book(request, guest, a.id)).status).toBe(201);
    const before = await state(a.id);
    const again = await book(request, guest, a.id);
    expect([again.status, await errorCode(again)]).toEqual([409, 'already_booked']);
    expect(await state(a.id)).toEqual(before);
    expect(await rejectionReasons(guest.id)).toEqual([{ reason: 'already_booked', activityId: a.id }]);
  });

  // V-BK-3 (FR-002, FR-003, FR-009)
  describe('closed activities', () => {
    test('sold out', async () => {
      const a = await createActivity(request, host, { capacity: 1 });
      expect((await book(request, tunde, a.id)).status).toBe(201);
      const guest = await signIn(request, 'Late Guest');
      const before = await state(a.id);
      const res = await book(request, guest, a.id);
      expect([res.status, await errorCode(res)]).toEqual([409, 'sold_out']);
      expect(await state(a.id)).toEqual(before);
      expect(await rejectionReasons(guest.id)).toEqual([{ reason: 'sold_out', activityId: a.id }]);
    });

    test('started', async () => {
      const a = await createActivity(request, host);
      await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${a.id}`;
      const res = await book(request, tunde, a.id);
      expect([res.status, await errorCode(res)]).toEqual([409, 'activity_started']);
      expect((await state(a.id)).bookings).toBe(0);
    });

    test('paused', async () => {
      const a = await createActivity(request, host);
      await t.admin`UPDATE activities SET bookings_paused = true WHERE id = ${a.id}`;
      const res = await book(request, tunde, a.id);
      expect([res.status, await errorCode(res)]).toEqual([409, 'bookings_paused']);
    });

    test('precedence: started, then paused, then sold out', async () => {
      // Sold out is simulated with spots_left = 0: the location lock stops starts_at moving once
      // someone has booked, even for the superuser.
      const a = await createActivity(request, host, { capacity: 1 });
      await t.admin`UPDATE activities SET spots_left = 0, bookings_paused = true,
                           starts_at = now() - interval '1 minute' WHERE id = ${a.id}`;
      expect(await errorCode(await book(request, tunde, a.id))).toBe('activity_started');
      await t.admin`UPDATE activities SET starts_at = now() + interval '1 day' WHERE id = ${a.id}`;
      expect(await errorCode(await book(request, tunde, a.id))).toBe('bookings_paused');
      await t.admin`UPDATE activities SET bookings_paused = false WHERE id = ${a.id}`;
      expect(await errorCode(await book(request, tunde, a.id))).toBe('sold_out');
    });

    test('already_booked comes before the closed reasons', async () => {
      const a = await createActivity(request, host, { capacity: 1 });
      expect((await book(request, tunde, a.id)).status).toBe(201);
      await t.admin`UPDATE activities SET bookings_paused = true WHERE id = ${a.id}`;
      expect(await errorCode(await book(request, tunde, a.id))).toBe('already_booked');
    });
  });

  // V-BK-4 (FR-004)
  describe('idempotency', () => {
    test('the same key replays the original booking with 200 and writes nothing', async () => {
      const a = await createActivity(request, host);
      const guest = await signIn(request, 'Retrying Guest');
      const key = randomUUID();
      const first = (await (await book(request, guest, a.id, key)).json()) as BookingBody;
      const before = await state(a.id);
      const [{ count: eventsBefore }] = (await t.admin`SELECT count(*)::int FROM events`) as [
        { count: number },
      ];

      const replay = await book(request, guest, a.id, key);
      expect(replay.status).toBe(200);
      const body = (await replay.json()) as BookingBody;
      expect(body.booking).toEqual(first.booking);
      expect(body.activity).toEqual(first.activity);
      expect(await state(a.id)).toEqual(before);
      const [{ count: eventsAfter }] = (await t.admin`SELECT count(*)::int FROM events`) as [
        { count: number },
      ];
      expect(eventsAfter).toBe(eventsBefore);
    });

    test('the same key for another activity is idempotency_conflict', async () => {
      const a = await createActivity(request, host);
      const b = await createActivity(request, host);
      const guest = await signIn(request, 'Key Reuser');
      const key = randomUUID();
      expect((await book(request, guest, a.id, key)).status).toBe(201);
      const res = await book(request, guest, b.id, key);
      expect([res.status, await errorCode(res)]).toEqual([409, 'idempotency_conflict']);
      expect((await state(b.id)).bookings).toBe(0);
    });

    test('a replay after host removal returns the booking as removed', async () => {
      const a = await createActivity(request, host);
      const guest = await signIn(request, 'Removed Retrier');
      const key = randomUUID();
      const first = (await (await book(request, guest, a.id, key)).json()) as BookingBody;
      expect((await removeBooking(request, host, first.booking.id)).status).toBe(200);
      const replay = await book(request, guest, a.id, key);
      expect(replay.status).toBe(200);
      expect(((await replay.json()) as BookingBody).booking).toMatchObject({
        id: first.booking.id,
        status: 'removed',
      });
    });
  });

  // FR-018
  test('a person the host removed cannot book that activity again', async () => {
    const a = await createActivity(request, host);
    const guest = await signIn(request, 'Removed Guest');
    const first = (await (await book(request, guest, a.id)).json()) as BookingBody;
    await removeBooking(request, host, first.booking.id);
    const before = await state(a.id);
    const res = await book(request, guest, a.id);
    expect([res.status, await errorCode(res)]).toEqual([409, 'booking_removed']);
    expect(await state(a.id)).toEqual(before);
  });
});

describe('POST /api/host/bookings/:id/removal', () => {
  async function booked() {
    const a = await createActivity(request, host, { capacity: 2 });
    const guest = await signIn(request, 'Guest To Remove');
    const body = (await (await book(request, guest, a.id)).json()) as BookingBody;
    return { activityId: a.id, bookingId: body.booking.id };
  }

  // V-RM-1 (FR-012)
  test('the host removes a confirmed booking and frees its spot', async () => {
    const { activityId, bookingId } = await booked();
    const before = await state(activityId);
    const res = await removeBooking(request, host, bookingId);
    expect(res.status).toBe(200);
    const body = (await res.json()) as BookingBody;
    expect(body.booking).toMatchObject({ id: bookingId, status: 'removed' });
    expect(body.activity).toEqual({
      id: activityId,
      spotsLeft: before.spots_left + 1,
      version: before.version + 1,
    });
    const removals = await t.admin`SELECT removed_by FROM booking_removals WHERE booking_id = ${bookingId}`;
    expect([...removals]).toEqual([{ removed_by: host.id }]);
  });

  // V-RM-2 (FR-012)
  test('removing again returns 200 and frees nothing more', async () => {
    const { activityId, bookingId } = await booked();
    await removeBooking(request, host, bookingId);
    const before = await state(activityId);
    const res = await removeBooking(request, host, bookingId);
    expect(res.status).toBe(200);
    expect(((await res.json()) as BookingBody).booking.status).toBe('removed');
    expect(await state(activityId)).toEqual(before);
    const [{ count }] = (await t.admin`
      SELECT count(*)::int FROM booking_removals WHERE booking_id = ${bookingId}`) as [{ count: number }];
    expect(count).toBe(1);
  });

  // V-RM-3 (FR-012, SEC-001)
  test('non-host → 403, unknown booking → 404, no session → 401', async () => {
    const { activityId, bookingId } = await booked();
    const before = await state(activityId);
    const denied = await removeBooking(request, tunde, bookingId);
    expect([denied.status, await errorCode(denied)]).toEqual([403, 'forbidden']);
    expect((await removeBooking(request, host, UNKNOWN_ID)).status).toBe(404);
    expect((await removeBooking(request, { id: '', headers: {} }, bookingId)).status).toBe(401);
    expect(await state(activityId)).toEqual(before);
  });

  // V-RM-4 (FR-012)
  test('the freed spot goes to the next booker', async () => {
    const a = await createActivity(request, host, { capacity: 1 });
    const first = (await (await book(request, tunde, a.id)).json()) as BookingBody;
    const next = await signIn(request, 'Next In Line');
    expect(await errorCode(await book(request, next, a.id))).toBe('sold_out');
    await removeBooking(request, host, first.booking.id);
    expect((await book(request, next, a.id)).status).toBe(201);
  });
});
