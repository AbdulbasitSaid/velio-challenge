import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { AggregationTemporality, MeterProvider, MetricReader } from '@opentelemetry/sdk-metrics';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { createDb, type Db } from '../../src/db/client';
import { createLogger } from '../../src/telemetry/logger';
import { TEST_PEPPER } from '../helpers/app';
import {
  book,
  createActivity,
  errorCode,
  overHttp,
  patchActivity,
  removeBooking,
  signIn,
  signInMany,
  type BookingBody,
  type Caller,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

// PLANNING §4.8: real HTTP through Bun.serve and a pool of 20, so requests contend at the
// database rather than being serialized by the test. Assertions are on outcomes, never timings.

class TestReader extends MetricReader {
  protected async onForceFlush() {}
  protected async onShutdown() {}
}

const M = 200;
const ROUNDS = 3;

let t: TestDatabase;
let db: Db;
let server: ReturnType<typeof Bun.serve>;
let request: Requester;
let host: Caller;
let users: Caller[];
const reader = new TestReader({ aggregationTemporalitySelector: () => AggregationTemporality.CUMULATIVE });

beforeAll(async () => {
  t = await createTestDatabase();
  db = createDb(t.url, { max: 20 });
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
    HOLDOUT_PERCENT: '0',
  });
  const app = createApp({
    config,
    db,
    logger: createLogger('silent'),
    clock: () => new Date(),
    meterProvider: new MeterProvider({ readers: [reader] }),
  });
  server = Bun.serve({ port: 0, fetch: app.fetch });
  request = overHttp(`http://localhost:${server.port}`);
  host = await signIn(request, 'Amara Okafor');
  users = await signInMany(request, M);
}, 60_000);

afterAll(async () => {
  await server.stop(true);
  await db.destroy();
  await t.drop();
});

/** AC-006: capacity − spots_left equals confirmed bookings, and spots_left is never negative. */
async function expectInvariant(activityId: string) {
  const [row] = await t.admin<{ capacity: number; spots_left: number; confirmed: number }[]>`
    SELECT capacity, spots_left,
           (SELECT count(*)::int FROM bookings WHERE activity_id = a.id AND status = 'confirmed') AS confirmed
      FROM activities a WHERE id = ${activityId}`;
  expect(row!.spots_left).toBeGreaterThanOrEqual(0);
  expect(row!.capacity - row!.spots_left).toBe(row!.confirmed);
  return row!;
}

async function outcome(res: Response): Promise<string> {
  return res.status === 201 || res.status === 200 ? String(res.status) : await errorCode(res);
}

function tally(outcomes: string[]) {
  const counts: Record<string, number> = {};
  for (const o of outcomes) counts[o] = (counts[o] ?? 0) + 1;
  return counts;
}

// V-CC-1 (NFR-002, AC-001, AC-006)
describe('the last spots', () => {
  for (const n of [1, 5, 14]) {
    test(`${M} parallel bookers for ${n} spot(s): exactly ${n} succeed, ${ROUNDS} rounds`, async () => {
      for (let round = 0; round < ROUNDS; round++) {
        const activity = await createActivity(request, host, { capacity: n });
        const responses = await Promise.all(users.map((u) => book(request, u, activity.id)));
        const bodies = await Promise.all(
          responses.map(async (res) => ({ status: res.status, body: (await res.json()) as unknown })),
        );

        const won = bodies.filter((b) => b.status === 201).map((b) => b.body as BookingBody);
        const lost = bodies.filter((b) => b.status !== 201);
        expect(won).toHaveLength(n);
        expect(lost).toHaveLength(M - n);
        for (const l of lost) {
          expect(l.status).toBe(409);
          expect((l.body as { error: { code: string } }).error.code).toBe('sold_out');
        }

        const row = await expectInvariant(activity.id);
        expect(row).toMatchObject({ spots_left: 0, confirmed: n });
        expect(new Set(won.map((w) => w.booking.ref)).size).toBe(n);
        expect(new Set(won.map((w) => w.booking.planId)).size).toBe(n);
      }
    }, 60_000);
  }

  test('the bookings contended for the activity row', async () => {
    const { resourceMetrics } = await reader.collect();
    const wait = resourceMetrics.scopeMetrics
      .flatMap((sm) => sm.metrics)
      .find((m) => m.descriptor.name === 'booking_row_wait_seconds');
    const point = wait!.dataPoints[0]!.value as { count: number; max?: number };
    expect(point.count).toBeGreaterThan(0);
    expect(point.max).toBeGreaterThan(0);
  });
});

// V-CC-2 (FR-004, AC-002)
test('one user, one key, 20 in parallel: one booking, every response carries it', async () => {
  const activity = await createActivity(request, host, { capacity: 14 });
  const key = randomUUID();
  const responses = await Promise.all(
    Array.from({ length: 20 }, () => book(request, users[0]!, activity.id, key)),
  );
  const statuses = responses.map((r) => r.status);
  const bodies = (await Promise.all(responses.map((r) => r.json()))) as BookingBody[];

  expect(tally(statuses.map(String))).toEqual({ '201': 1, '200': 19 });
  expect(new Set(bodies.map((b) => b.booking.id)).size).toBe(1);
  expect((await expectInvariant(activity.id)).spots_left).toBe(13);
}, 30_000);

test('one user, one key, 20 in parallel for the last spot: replays, not sold_out', async () => {
  const activity = await createActivity(request, host, { capacity: 1 });
  const key = randomUUID();
  const responses = await Promise.all(
    Array.from({ length: 20 }, () => book(request, users[1]!, activity.id, key)),
  );
  expect(tally(await Promise.all(responses.map(outcome)))).toEqual({ '201': 1, '200': 19 });
  expect((await expectInvariant(activity.id)).spots_left).toBe(0);
}, 30_000);

// V-CC-3 (FR-005)
test('one user, 20 new keys in parallel: one booking, the rest already_booked', async () => {
  const activity = await createActivity(request, host, { capacity: 14 });
  const responses = await Promise.all(
    Array.from({ length: 20 }, () => book(request, users[2]!, activity.id)),
  );
  expect(tally(await Promise.all(responses.map(outcome)))).toEqual({ '201': 1, already_booked: 19 });
  expect((await expectInvariant(activity.id)).spots_left).toBe(13);
}, 30_000);

// V-CC-4 (FR-012, AC-003, NFR-004)
test('a removal racing 20 bookings on a sold-out activity: exactly one takes the freed spot', async () => {
  for (let round = 0; round < ROUNDS; round++) {
    const activity = await createActivity(request, host, { capacity: 1 });
    const holder = users[3 + round]!;
    const held = (await (await book(request, holder, activity.id)).json()) as BookingBody;
    const racers = users.slice(10, 30);

    // Each racer keeps trying until one of its attempts started after the removal returned, so
    // the freed spot is always contested and the expected count is exact.
    let removalDone = false;
    const removal = removeBooking(request, host, held.booking.id).then((res) => {
      removalDone = true;
      return res.status;
    });
    const results = racers.map(async (racer) => {
      const key = randomUUID();
      for (let attempt = 0; attempt < 1000; attempt++) {
        const afterRemoval = removalDone;
        const res = await book(request, racer, activity.id, key);
        const o = await outcome(res);
        if (o !== 'sold_out' || afterRemoval) return o;
      }
      return 'gave_up';
    });

    expect(await removal).toBe(200);
    expect(tally(await Promise.all(results))).toEqual({ '201': 1, sold_out: 19 });
    expect(await expectInvariant(activity.id)).toMatchObject({ spots_left: 0, confirmed: 1 });
  }
}, 60_000);

// V-CC-5 (FR-015, AC-006, NFR-004)
test('capacity raises and lowers interleaved with 50 parallel bookings keep the invariant', async () => {
  for (let round = 0; round < ROUNDS; round++) {
    const activity = await createActivity(request, host, { capacity: 20 });
    const bookings = users.slice(50, 100).map(async (u) => outcome(await book(request, u, activity.id)));
    const edits = [25, 10, 30, 15, 40, 5].map(async (capacity) =>
      outcome(await patchActivity(request, host, activity.id, { capacity })),
    );

    const bookingOutcomes = await Promise.all(bookings);
    const editOutcomes = await Promise.all(edits);
    for (const o of bookingOutcomes) expect(['201', 'sold_out']).toContain(o);
    for (const o of editOutcomes) expect(['200', 'capacity_below_bookings']).toContain(o);

    const row = await expectInvariant(activity.id);
    expect(row.confirmed).toBe(bookingOutcomes.filter((o) => o === '201').length);
  }
}, 60_000);
