import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import {
  AggregationTemporality,
  MeterProvider,
  MetricReader,
  type ResourceMetrics,
} from '@opentelemetry/sdk-metrics';
import { changeCapacity, createBookingEngine, type BookingEngine } from '../../src/modules/bookings/engine';
import { createBookingMetrics } from '../../src/modules/bookings/metrics';
import { newBookingRef } from '../../src/modules/bookings/ref';
import { createLogger } from '../../src/telemetry/logger';
import { createTestDatabase, type TestDatabase } from '../helpers/db';
import { insertActivity, insertBooking, insertPlan, insertUser } from '../helpers/fixtures';

class TestReader extends MetricReader {
  protected async onForceFlush() {}
  protected async onShutdown() {}
}

let t: TestDatabase;
let reader: TestReader;
let metricsProvider: MeterProvider;
const logLines: Record<string, unknown>[] = [];
const rawLog: string[] = [];

function engine(newRef?: () => string): BookingEngine {
  const sink = new Writable({
    write(chunk, _enc, done) {
      const text = chunk.toString();
      rawLog.push(text);
      for (const line of text.split('\n').filter(Boolean)) logLines.push(JSON.parse(line));
      done();
    },
  });
  return createBookingEngine({
    db: t.db,
    logger: createLogger('info', sink),
    metrics: createBookingMetrics(metricsProvider),
    newRef,
  });
}

beforeAll(async () => {
  t = await createTestDatabase();
  reader = new TestReader({ aggregationTemporalitySelector: () => AggregationTemporality.CUMULATIVE });
  metricsProvider = new MeterProvider({ readers: [reader] });
});

afterAll(async () => {
  await t.drop();
});

async function setup(overrides: Record<string, unknown> = {}) {
  const host = await insertUser(t.admin, 'Amara Okafor');
  const guest = await insertUser(t.admin, 'Tunde Adeyemi');
  const activityId = await insertActivity(t.admin, host, overrides);
  return { host, guest, activityId };
}

async function counts(activityId: string) {
  const [row] = await t.admin`
    SELECT spots_left, version::int,
           (SELECT count(*)::int FROM bookings WHERE activity_id = a.id) AS bookings,
           (SELECT count(*)::int FROM plans WHERE activity_id = a.id) AS plans,
           (SELECT count(*)::int FROM events WHERE activity_id = a.id) AS events
      FROM activities a WHERE id = ${activityId}`;
  return row!;
}

const direct = (activityId: string, userId: string) => ({
  activityId,
  userId,
  idempotencyKey: randomUUID(),
  source: 'direct' as const,
});

// V-BK-6 (FR-007)
describe('booking reference', () => {
  test('10,000 references match the pattern', () => {
    for (let i = 0; i < 10_000; i++)
      expect(newBookingRef()).toMatch(/^VLO-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{5}$/);
  });

  test('a collision is retried with a new reference', async () => {
    const { host, guest, activityId } = await setup();
    const plan = await insertPlan(t.admin, activityId, host);
    const taken = 'VLO-AAAAA';
    await insertBooking(t.admin, { activityId, userId: host, planId: plan, ref: taken });
    const refs = [taken, 'VLO-BBBBB'];
    const result = await engine(() => refs.shift()!).bookSpot(direct(activityId, guest));
    expect(result.booking.ref).toBe('VLO-BBBBB');
  });

  test('more than five collisions fail and write nothing', async () => {
    const { host, guest, activityId } = await setup();
    const plan = await insertPlan(t.admin, activityId, host);
    await insertBooking(t.admin, { activityId, userId: host, planId: plan, ref: 'VLO-CCCCC' });
    const before = await counts(activityId);
    const failing = engine(() => 'VLO-CCCCC').bookSpot(direct(activityId, guest));
    expect(failing).rejects.toThrow('collided');
    await failing.catch(() => {});
    expect(await counts(activityId)).toEqual(before);
  });
});

// V-BK-7 (FR-010)
describe('extension point for claims', () => {
  test('joins the given Plan and commits rows written by extend', async () => {
    const { host, guest, activityId } = await setup();
    const planId = await insertPlan(t.admin, activityId, host);
    const result = await engine().bookSpot({
      ...direct(activityId, guest),
      planId,
      extend: async (tx, booking) => {
        await tx
          .insertInto('events')
          .values({ name: 'extend_probe', activity_id: booking.activity_id })
          .execute();
      },
    });
    expect(result.booking.plan_id).toBe(planId);
    const probes =
      await t.admin`SELECT 1 FROM events WHERE name = 'extend_probe' AND activity_id = ${activityId}`;
    expect(probes).toHaveLength(1);
    expect((await counts(activityId)).plans).toBe(1);
  });

  test('a throwing extend rolls back the spot, booking and its rows', async () => {
    const { guest, activityId } = await setup();
    const before = await counts(activityId);
    const failing = engine().bookSpot({
      ...direct(activityId, guest),
      extend: async (tx, booking) => {
        await tx
          .insertInto('events')
          .values({ name: 'extend_probe', activity_id: booking.activity_id })
          .execute();
        // Not an ApiError: a typed rejection would also record a booking_rejected event (S4).
        throw new Error('extend failed');
      },
    });
    expect(failing).rejects.toThrow('extend failed');
    await failing.catch(() => {});
    expect(await counts(activityId)).toEqual(before);
  });
});

// V-BK-8 (FR-011)
describe('pg_notify', () => {
  test('one notification per committed change, none for a rejection', async () => {
    const { host, guest, activityId } = await setup({ capacity: 2, spots_left: 2 });
    const received: { activityId: string; spotsLeft: number; version: number; committedAt: string }[] = [];
    const listener = await t.admin.listen('activity_spots', (payload) => {
      const msg = JSON.parse(payload);
      if (msg.activityId === activityId) received.push(msg);
    });

    const e = engine();
    const booked = await e.bookSpot(direct(activityId, guest));
    const second = await insertUser(t.admin, 'Zainab Bello');
    await e.bookSpot(direct(activityId, second));
    const third = await insertUser(t.admin, 'Late Guest');
    expect(e.bookSpot(direct(activityId, third))).rejects.toThrow('No spots left.');
    await e.removeBooking({ bookingId: booked.booking.id, hostId: host });
    await t.db.transaction().execute((tx) => changeCapacity(tx, activityId, 5));
    // A no-op capacity change notifies nothing.
    await t.db.transaction().execute((tx) => changeCapacity(tx, activityId, 5));

    const deadline = Date.now() + 2000;
    while (received.length < 4 && Date.now() < deadline) await Bun.sleep(20);
    await Bun.sleep(100);
    await listener.unlisten();

    expect(received.map(({ spotsLeft, version }) => ({ spotsLeft, version }))).toEqual([
      { spotsLeft: 1, version: 1 },
      { spotsLeft: 0, version: 2 },
      { spotsLeft: 1, version: 3 },
      { spotsLeft: 4, version: 4 },
    ]);
    for (const msg of received) expect(Date.parse(msg.committedAt)).not.toBeNaN();
  });
});

function points(rm: ResourceMetrics, name: string) {
  return rm.scopeMetrics
    .flatMap((sm) => sm.metrics)
    .filter((m) => m.descriptor.name === name)
    .flatMap((m) => m.dataPoints as { attributes: Record<string, unknown>; value: unknown }[]);
}

// V-OBS-1 (NFR-005, SEC-002)
describe('metrics', () => {
  test('instruments carry only their listed labels', async () => {
    const { host, guest, activityId } = await setup({ capacity: 1, spots_left: 1 });
    const e = engine();
    const key = randomUUID();
    const booked = await e.bookSpot({ ...direct(activityId, guest), idempotencyKey: key });
    await e.bookSpot({ ...direct(activityId, guest), idempotencyKey: key });
    await e.bookSpot(direct(activityId, host)).catch(() => {});
    await e.bookSpot(direct(activityId, await insertUser(t.admin, 'Sold Out Guest'))).catch(() => {});
    await e.removeBooking({ bookingId: booked.booking.id, hostId: host });
    await e.removeBooking({ bookingId: booked.booking.id, hostId: host });

    const { resourceMetrics } = await reader.collect();
    const outcomes = points(resourceMetrics, 'booking_attempts_total').map((p) => p.attributes);
    expect(outcomes).toEqual(
      expect.arrayContaining([
        { outcome: 'success', path: 'direct' },
        { outcome: 'replay', path: 'direct' },
        { outcome: 'forbidden', path: 'direct' },
        { outcome: 'sold_out', path: 'direct' },
      ]),
    );
    for (const name of ['booking_attempts_total', 'booking_duration_seconds']) {
      for (const p of points(resourceMetrics, name))
        expect(Object.keys(p.attributes).sort()).toEqual(['outcome', 'path']);
    }
    for (const name of ['booking_row_wait_seconds', 'oversell_detected_total']) {
      for (const p of points(resourceMetrics, name)) expect(p.attributes).toEqual({});
    }
    expect(points(resourceMetrics, 'booking_row_wait_seconds')).toHaveLength(1);
    expect(points(resourceMetrics, 'booking_removals_total').map((p) => p.attributes)).toEqual(
      expect.arrayContaining([{ outcome: 'removed' }, { outcome: 'already_removed' }]),
    );
    const labelText = JSON.stringify(
      resourceMetrics.scopeMetrics.flatMap((sm) =>
        sm.metrics.map((m) => m.dataPoints.map((d) => d.attributes)),
      ),
    );
    for (const id of [activityId, guest, host, key, booked.booking.ref]) expect(labelText).not.toContain(id);
  });
});

// V-OBS-2 (FR-017)
describe('oversell assertion', () => {
  test('a broken invariant is logged and counted; the booking still succeeds', async () => {
    const { guest, activityId } = await setup();
    const e = engine();
    await e.bookSpot(direct(activityId, guest));
    // Bypass the engine: a spot appears without a booking being removed.
    await t.admin`UPDATE activities SET spots_left = spots_left + 1 WHERE id = ${activityId}`;
    logLines.length = 0;
    rawLog.length = 0;
    // Earlier fixtures insert bookings without taking a spot, so count the change only.
    const oversells = async () =>
      points((await reader.collect()).resourceMetrics, 'oversell_detected_total').reduce(
        (sum, p) => sum + Number(p.value),
        0,
      );
    const before = await oversells();

    const next = await insertUser(t.admin, 'Zainab Bello');
    const result = await e.bookSpot(direct(activityId, next));
    expect(result.created).toBe(true);

    const alarm = logLines.find((l) => l.msg === 'oversell_detected');
    expect(alarm).toMatchObject({ level: 'error', activity_id: activityId });
    expect(rawLog.join('')).not.toContain(next);
    expect((await oversells()) - before).toBe(1);
  });
});
