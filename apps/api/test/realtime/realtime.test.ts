import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import {
  AggregationTemporality,
  MeterProvider,
  MetricReader,
  type ResourceMetrics,
} from '@opentelemetry/sdk-metrics';
import type { SpotsEvent } from '@velio/contracts';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { createDb, type Db } from '../../src/db/client';
import { createBookingEngine } from '../../src/modules/bookings/engine';
import { createBookingMetrics } from '../../src/modules/bookings/metrics';
import { createRealtime, type Realtime } from '../../src/modules/realtime/gateway';
import { notifyAttendance } from '../../src/modules/realtime/notify';
import { createLogger } from '../../src/telemetry/logger';
import { TEST_PEPPER } from '../helpers/app';
import {
  book,
  createActivity,
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
import { insertActivity } from '../helpers/fixtures';
import { connectWs, type WsClient } from '../helpers/ws';

// S3 VALIDATION V-RT-*: a real Bun.serve, real Postgres LISTEN/NOTIFY and real WebSockets.

class TestReader extends MetricReader {
  protected async onForceFlush() {}
  protected async onShutdown() {}
}

const PING_MS = 200;

let t: TestDatabase;
let db: Db;
let realtime: Realtime;
let server: ReturnType<typeof Bun.serve>;
let base: string;
let request: Requester;
let host: Caller;
let tunde: Caller;
let zainab: Caller;
const reader = new TestReader({ aggregationTemporalitySelector: () => AggregationTemporality.CUMULATIVE });
const meterProvider = new MeterProvider({ readers: [reader] });
const clients: WsClient[] = [];

beforeAll(async () => {
  t = await createTestDatabase();
  db = createDb(t.url, { max: 20 });
  const logger = createLogger('silent');
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
  });
  realtime = createRealtime({ db, logger, listenUrl: t.url, meterProvider, pingIntervalMs: PING_MS });
  const app = createApp({ config, db, logger, clock: () => new Date(), realtime });
  server = Bun.serve({ port: 0, fetch: app.fetch, websocket: realtime.websocket });
  realtime.attach(server);
  await realtime.start();
  base = `http://localhost:${server.port}`;
  request = overHttp(base);
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
  zainab = await signIn(request, 'Zainab Okafor');
}, 30_000);

afterAll(async () => {
  for (const c of clients) c.close();
  realtime.closeSockets();
  await server.stop(true);
  await realtime.stop();
  await db.destroy();
  await t.drop();
});

async function connect(options: Parameters<typeof connectWs>[1] = {}) {
  const c = await connectWs(base, options);
  clients.push(c);
  return c;
}

/** Subscribes and waits for the answer: `subscribed` for accepted topics, `error` per rejection. */
async function subscribe(c: WsClient, topics: string[]) {
  const before = c.messages.length;
  const done = c.waitFor(
    () =>
      c.messages
        .slice(before)
        .reduce((n, m) => n + (m.type === 'subscribed' ? m.topics.length : m.type === 'error' ? 1 : 0), 0) >=
      topics.length,
  );
  c.send({ type: 'subscribe', topics });
  await done;
  return c.messages.slice(before);
}

const spotsFor = (c: WsClient, activityId: string) =>
  c.messages.filter((m): m is SpotsEvent => m.type === 'spots' && m.activityId === activityId);

/** Waits until no new message arrives for `ms`, so "nothing else came" assertions are meaningful. */
const settle = (ms = 300) => Bun.sleep(ms);

async function collect(): Promise<ResourceMetrics> {
  const { resourceMetrics } = await reader.collect();
  return resourceMetrics;
}

function metric(rm: ResourceMetrics, name: string) {
  return rm.scopeMetrics.flatMap((s) => s.metrics).find((m) => m.descriptor.name === name);
}

describe('events', () => {
  // V-RT-1 (FR-008, FR-010, AC-001)
  test('booking, removal and capacity change each reach every subscriber; rejections send nothing', async () => {
    const a = await createActivity(request, host, { capacity: 1 });
    const b = await createActivity(request, host, { capacity: 3 });
    const one = await connect();
    const two = await connect({ platform: 'ios' });
    const other = await connect({ platform: 'android' });
    await subscribe(one, [`activity:${a.id}`]);
    await subscribe(two, [`activity:${a.id}`]);
    await subscribe(other, [`activity:${b.id}`]);

    const booked = (await (await book(request, tunde, a.id)).json()) as BookingBody;
    await removeBooking(request, host, booked.booking.id);
    await patchActivity(request, host, a.id, { capacity: 2 });
    await book(request, zainab, a.id); // takes a spot: 4th event
    expect((await book(request, zainab, a.id)).status).toBe(409); // already_booked: no event
    await settle();

    for (const c of [one, two]) {
      expect(spotsFor(c, a.id).map((e) => [e.spotsLeft, e.version])).toEqual([
        [0, 1],
        [1, 2],
        [2, 3],
        [1, 4],
      ]);
    }
    expect(other.messages.filter((m) => m.type === 'spots')).toHaveLength(0);
  });

  // V-RT-4 (FR-011)
  test('50 parallel bookings arrive with strictly increasing versions', async () => {
    const a = await createActivity(request, host, { capacity: 50 });
    const people = await signInMany(request, 50, 'Parallel');
    const c = await connect();
    await subscribe(c, [`activity:${a.id}`]);
    const last = c.waitFor((m) => m.type === 'spots' && m.spotsLeft === 0, 15_000);
    const results = await Promise.all(people.map((p) => book(request, p, a.id)));
    expect(results.every((r) => r.status === 201)).toBe(true);
    await last;
    const versions = spotsFor(c, a.id).map((e) => e.version);
    expect(versions).toHaveLength(50);
    expect(versions).toEqual([...versions].sort((x, y) => x - y));
    expect(new Set(versions).size).toBe(50);
  }, 30_000);

  // V-RT-5 (FR-009)
  test('plan and attendance hints', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    const tundeBooking = (await (await book(request, tunde, a.id)).json()) as BookingBody;
    const planId = tundeBooking.booking.planId;
    const member = await connect({ headers: tunde.headers });
    const hostWs = await connect({ headers: host.headers });
    await subscribe(member, [`plan:${planId}`]);
    await subscribe(hostWs, [`host:${a.id}`]);

    // A booking into an existing Plan, through the S2 extension point S4's claims will use.
    const engine = createBookingEngine({
      db,
      logger: createLogger('silent'),
      metrics: createBookingMetrics(meterProvider),
    });
    const joined = await engine.bookSpot({
      activityId: a.id,
      userId: zainab.id,
      idempotencyKey: randomUUID(),
      source: 'vouch',
      planId,
    });
    await member.waitFor((m) => m.type === 'plan' && m.planId === planId);
    await hostWs.waitFor((m) => m.type === 'attendance' && m.activityId === a.id);

    const planHints = () => member.messages.filter((m) => m.type === 'plan').length;
    const attendanceHints = () => hostWs.messages.filter((m) => m.type === 'attendance').length;
    await removeBooking(request, host, joined.booking.id);
    await settle();
    expect(planHints()).toBe(2);
    expect(attendanceHints()).toBe(2);

    await db.transaction().execute((tx) => notifyAttendance(tx, a.id));
    await settle();
    expect(attendanceHints()).toBe(3);
    // The host topic also carries spots events.
    expect(spotsFor(hostWs, a.id).length).toBe(2);
  });
});

describe('connection and topics', () => {
  // V-RT-2 (FR-005, SEC-003)
  test('upgrade validation and the production origin check', async () => {
    expect((await fetch(`${base}/api/ws`)).status).toBe(400);
    expect((await fetch(`${base}/api/ws?platform=desktop`)).status).toBe(400);
    // A plain GET with a valid platform is not an upgrade.
    expect((await fetch(`${base}/api/ws?platform=web`)).status).toBe(400);

    const prod = createApp({
      config: loadConfig({
        NODE_ENV: 'production',
        DATABASE_URL: t.url,
        DATABASE_LISTEN_URL: t.url,
        CONTACT_PEPPER: TEST_PEPPER,
        ORIGIN_VERIFY_SECRET: 'x'.repeat(32),
        PUBLIC_BASE_URL: 'https://example.cloudfront.net',
        PHOTOS_BUCKET: 'velio-photos-test',
      }),
      db,
      logger: createLogger('silent'),
      clock: () => new Date(),
      realtime,
    });
    expect((await prod.request('/api/ws?platform=web')).status).toBe(403);
  });

  // V-RT-3 (FR-006, FR-007, AC-004, SEC-002)
  test('topic authorization', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    const planId = ((await (await book(request, tunde, a.id)).json()) as BookingBody).booking.planId;
    const plan = `plan:${planId}`;
    const hostTopic = `host:${a.id}`;
    const unknown = `activity:${randomUUID()}`;

    const anon = await connect();
    expect(await subscribe(anon, [`activity:${a.id}`, plan, hostTopic, unknown])).toEqual([
      { type: 'error', code: 'forbidden', topic: plan },
      { type: 'error', code: 'forbidden', topic: hostTopic },
      { type: 'error', code: 'not_found', topic: unknown },
      { type: 'subscribed', topics: [`activity:${a.id}`] },
    ]);

    const outsider = await connect({ headers: zainab.headers });
    expect(await subscribe(outsider, [plan, hostTopic])).toEqual([
      { type: 'error', code: 'forbidden', topic: plan },
      { type: 'error', code: 'forbidden', topic: hostTopic },
    ]);

    // Bearer for the member; a session cookie identifies the host the same way.
    const member = await connect({ headers: tunde.headers });
    const activity = `activity:${a.id}`;
    expect(await subscribe(member, [plan, activity])).toEqual([
      { type: 'subscribed', topics: [plan, activity] },
    ]);
    const cookie = `velio_session=${host.headers.authorization!.slice('Bearer '.length)}`;
    const hostWs = await connect({ headers: { cookie } });
    expect(await subscribe(hostWs, [hostTopic])).toEqual([{ type: 'subscribed', topics: [hostTopic] }]);

    // Unsubscribe stops delivery.
    member.send({ type: 'unsubscribe', topics: [activity] });
    await settle(100);
    await book(request, zainab, a.id);
    await settle();
    expect(spotsFor(member, a.id)).toHaveLength(0);
    expect(spotsFor(anon, a.id)).toHaveLength(1);
  });

  // V-RT-8 (FR-014)
  test('malformed messages, oversize frames and the topic limit', async () => {
    const c = await connect();
    const errors = () => c.messages.filter((m) => m.type === 'error').length;
    c.sendRaw('not json');
    c.send({ type: 'nope' });
    c.sendRaw(JSON.stringify({ type: 'subscribe', topics: ['x'.repeat(5_000)] }));
    await settle();
    expect(errors()).toBe(3);

    const hostId = host.id;
    const ids = await Promise.all(Array.from({ length: 21 }, () => insertActivity(t.admin, hostId)));
    await subscribe(
      c,
      ids.slice(0, 20).map((id) => `activity:${id}`),
    );
    const extra = `activity:${ids[20]}`;
    expect(await subscribe(c, [extra])).toEqual([{ type: 'error', code: 'validation_failed', topic: extra }]);

    const noisy = await connect();
    for (let i = 0; i < 20; i++) noisy.sendRaw('{');
    expect(await noisy.closed).toBe(1008);
  });

  // V-RT-9 (FR-015, FR-016)
  test('pings, and shutdown closes sockets with 1012', async () => {
    const c = await connect();
    await Bun.sleep(PING_MS * 3);
    expect(c.pings).toBeGreaterThan(0);

    const config = loadConfig({
      NODE_ENV: 'test',
      DATABASE_URL: t.url,
      DATABASE_LISTEN_URL: t.url,
      CONTACT_PEPPER: TEST_PEPPER,
    });
    const rt = createRealtime({ db, logger: createLogger('silent'), listenUrl: t.url, meterProvider });
    const app = createApp({
      config,
      db,
      logger: createLogger('silent'),
      clock: () => new Date(),
      realtime: rt,
    });
    const s = Bun.serve({ port: 0, fetch: app.fetch, websocket: rt.websocket });
    rt.attach(s);
    const victim = await connectWs(`http://localhost:${s.port}`);
    rt.closeSockets();
    expect(await victim.closed).toBe(1012);
    await s.stop(true);
    await rt.stop();
  });
});

describe('latency acks', () => {
  // V-RT-6 (FR-013, NFR-001, AC-002)
  test('100 acknowledged bookings give 100 samples under 2 s; bad acks are ignored', async () => {
    const before = await collect();
    const ignoredBefore = Number(metric(before, 'realtime_acks_ignored_total')?.dataPoints[0]?.value ?? 0);

    const a = await createActivity(request, host, { capacity: 100 });
    const people = await signInMany(request, 100, 'Acker');
    const c = await connect({ platform: 'android' });
    await subscribe(c, [`activity:${a.id}`]);
    for (const p of people) {
      const res = await book(request, p, a.id);
      const { activity } = (await res.json()) as BookingBody;
      await c.waitFor((m) => m.type === 'spots' && m.version === activity.version);
      c.send({ type: 'rendered', activityId: a.id, version: activity.version });
    }
    await settle();

    // Duplicate, unknown version, and an ack from a socket not subscribed to the activity.
    c.send({ type: 'rendered', activityId: a.id, version: 100 });
    c.send({ type: 'rendered', activityId: a.id, version: 999 });
    const stranger = await connect();
    stranger.send({ type: 'rendered', activityId: a.id, version: 50 });
    await settle();

    const rm = await collect();
    const hist = metric(rm, 'realtime_commit_to_ack_seconds')!;
    const point = hist.dataPoints.find((p) => p.attributes.platform === 'android')!;
    const value = point.value as { count: number; max?: number };
    expect(value.count).toBe(100);
    // Every sample ≤ 2 s means p95 ≤ 2 s.
    expect(value.max!).toBeLessThanOrEqual(2);
    const ignored = Number(metric(rm, 'realtime_acks_ignored_total')!.dataPoints[0]!.value);
    expect(ignored - ignoredBefore).toBe(3);
  }, 60_000);
});

describe('listener', () => {
  // V-RT-7 (FR-012, AC-003)
  test('a dropped LISTEN connection recovers and sends resync', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    const c = await connect();
    await subscribe(c, [`activity:${a.id}`]);
    const resync = c.waitFor((m) => m.type === 'resync', 10_000);
    const killed = await t.admin<{ ok: boolean }[]>`
      SELECT pg_terminate_backend(pid) AS ok FROM pg_stat_activity
       WHERE datname = ${t.name} AND query LIKE 'LISTEN%'`;
    expect(killed.length).toBe(1);
    await resync;
    expect(realtime.listening()).toBe(true);

    const res = await book(request, tunde, a.id);
    expect(res.status).toBe(201);
    await c.waitFor((m) => m.type === 'spots' && m.activityId === a.id);
    const reconnects = metric(await collect(), 'realtime_listener_reconnects_total')!;
    expect(Number(reconnects.dataPoints[0]!.value)).toBeGreaterThanOrEqual(1);
  }, 20_000);

  // V-RT-10 (FR-017)
  test('readiness waits for the listener', async () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      DATABASE_URL: t.url,
      DATABASE_LISTEN_URL: t.url,
      CONTACT_PEPPER: TEST_PEPPER,
    });
    const rt = createRealtime({ db, logger: createLogger('silent'), listenUrl: t.url, meterProvider });
    const app = createApp({
      config,
      db,
      logger: createLogger('silent'),
      clock: () => new Date(),
      realtime: rt,
    });
    expect((await app.request('/api/readyz')).status).toBe(503);
    await rt.start();
    expect((await app.request('/api/readyz')).status).toBe(200);
    await rt.stop();
    expect((await app.request('/api/readyz')).status).toBe(503);
  });
});

// V-OBS-1 (NFR-003, SEC-004). Runs last in the file, after the tests above produced data.
describe('telemetry', () => {
  test('resume=1 counts a reconnect', async () => {
    await connect({ query: 'platform=web&resume=1' });
    const m = metric(await collect(), 'realtime_reconnects_total')!;
    expect(m.dataPoints.map((p) => p.attributes)).toEqual([{ platform: 'web' }]);
  });

  test('realtime instruments carry only their listed labels', async () => {
    const rm = await collect();
    const allowed: Record<string, string[]> = {
      realtime_commit_to_ack_seconds: ['platform'],
      realtime_notify_lag_seconds: [],
      realtime_open_sockets: ['platform'],
      realtime_reconnects_total: ['platform'],
      realtime_events_published_total: ['type'],
      realtime_acks_ignored_total: [],
      realtime_listener_reconnects_total: [],
    };
    for (const [name, labels] of Object.entries(allowed)) {
      const m = metric(rm, name);
      expect(m).toBeDefined();
      for (const p of m!.dataPoints) expect(Object.keys(p.attributes).sort()).toEqual(labels);
    }
    const types = metric(rm, 'realtime_events_published_total')!.dataPoints.map((p) => p.attributes.type);
    expect(new Set(types)).toEqual(new Set(['spots', 'plan', 'attendance', 'resync']));
  });
});
