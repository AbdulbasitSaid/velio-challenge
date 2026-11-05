import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { AggregationTemporality, MeterProvider, MetricReader } from '@opentelemetry/sdk-metrics';
import { InviteView } from '@velio/contracts';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { contactHash, normaliseContact } from '../../src/modules/identity/contact';
import { newInviteCode, normaliseCode } from '../../src/modules/invites/codes';
import { createLogger } from '../../src/telemetry/logger';
import { TEST_PEPPER, testClock } from '../helpers/app';
import {
  bookOk,
  claim,
  createActivity,
  createInvite,
  errorCode,
  inProcess,
  newContact,
  openInvite,
  postInvite,
  removeBooking,
  signIn,
  viewInvite,
  type Caller,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

class TestReader extends MetricReader {
  protected async onForceFlush() {}
  protected async onShutdown() {}
}

const BASE = 'https://d1.cloudfront.net';
let t: TestDatabase;
let request: Requester;
let clock: ReturnType<typeof testClock>;
let host: Caller;
let tunde: Caller;
let zainab: Caller;
const reader = new TestReader({ aggregationTemporalitySelector: () => AggregationTemporality.CUMULATIVE });

beforeAll(async () => {
  t = await createTestDatabase();
  clock = testClock(new Date());
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
    HOLDOUT_PERCENT: '0',
    PUBLIC_BASE_URL: BASE,
    // Small thresholds so V-RL-2 and V-RL-3 don't need hundreds of requests.
    LINK_CLAIMS_PER_MINUTE: '3',
    AUTO_PAUSE_MIN_OPENS: '20',
  });
  const app = createApp({
    config,
    db: t.db,
    logger: createLogger('silent'),
    clock: clock.now,
    meterProvider: new MeterProvider({ readers: [reader] }),
  });
  request = inProcess(app);
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
  zainab = await signIn(request, 'Zainab Okafor');
});

afterAll(async () => {
  await t.drop();
});

/** An activity with Tunde booked in his own Plan. */
async function tundesPlan(capacity = 5) {
  const a = await createActivity(request, host, { capacity });
  const booking = await bookOk(request, tunde, a.id);
  return { activityId: a.id, planId: booking.booking.planId, bookingId: booking.booking.id };
}

describe('creating invites', () => {
  // V-INV-1 (FR-001, FR-003, SEC-001)
  test('a member creates a vouch: code, link, expiry, contact stored only as a hash', async () => {
    const { planId } = await tundesPlan();
    const contact = newContact();
    const res = await postInvite(request, tunde, planId, {
      rail: 'vouch',
      inviteeName: 'Zainab Okafor',
      contact,
      note: 'Come with me!',
    });
    expect(res.status).toBe(201);
    const inv = (await res.json()) as Record<string, unknown>;
    expect(inv.code).toMatch(/^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$/);
    expect(inv.link).toBe(`${BASE}/i/${inv.code as string}`);
    expect(inv).toMatchObject({
      rail: 'vouch',
      inviteeName: 'Zainab Okafor',
      note: 'Come with me!',
      status: 'created',
    });
    expect(JSON.stringify(inv)).not.toContain(contact);

    const [row] = await t.admin<{ invitee_contact_hash: Buffer; expires_at: Date; starts_at: Date }[]>`
      SELECT i.invitee_contact_hash, i.expires_at, a.starts_at
        FROM invites i JOIN activities a ON a.id = i.activity_id WHERE i.id = ${inv.id as string}`;
    expect(row!.expires_at.getTime()).toBe(row!.starts_at.getTime());
    expect(row!.invitee_contact_hash.equals(contactHash(TEST_PEPPER, normaliseContact(contact)))).toBe(true);
    // The raw contact is nowhere in the database's invite rows.
    const raw =
      await t.admin`SELECT 1 FROM invites WHERE row_to_json(invites)::text LIKE ${'%' + contact + '%'}`;
    expect(raw).toHaveLength(0);
  });

  // V-INV-2 (FR-001)
  test('rejections: non-member, removed member, unknown Plan, after start, bad bodies', async () => {
    const { planId, activityId } = await tundesPlan();
    const vouch = { rail: 'vouch', inviteeName: 'Kofi Mensah' };
    expect((await postInvite(request, zainab, planId, vouch)).status).toBe(403);
    expect((await postInvite(request, tunde, randomUUID(), vouch)).status).toBe(404);
    expect((await postInvite(request, tunde, planId, { rail: 'vouch' })).status).toBe(400);
    expect((await postInvite(request, tunde, planId, { rail: 'public', note: 'hi' })).status).toBe(201);
    expect((await postInvite(request, tunde, planId, { ...vouch, note: 'x'.repeat(281) })).status).toBe(400);
    expect((await postInvite(request, tunde, planId, { ...vouch, inviteeName: 'x'.repeat(81) })).status).toBe(
      400,
    );

    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${activityId}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    const started = await postInvite(request, tunde, planId, vouch);
    expect(started.status).toBe(409);
    expect(await errorCode(started)).toBe('activity_started');

    const second = await tundesPlan();
    await removeBooking(request, host, second.bookingId);
    expect((await postInvite(request, tunde, second.planId, vouch)).status).toBe(403);
  });

  // V-INV-3 (FR-002)
  test('one public link per member per Plan', async () => {
    const { planId } = await tundesPlan();
    const first = await postInvite(request, tunde, planId, { rail: 'public' });
    const again = await postInvite(request, tunde, planId, { rail: 'public' });
    expect(first.status).toBe(201);
    expect(again.status).toBe(200);
    const [a, b] = [(await first.json()) as { code: string }, (await again.json()) as { code: string }];
    expect(b.code).toBe(a.code);

    // Zainab joins Tunde's Plan through a vouch and gets her own public link.
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    expect((await claim(request, vouch.code, zainab)).status).toBe(201);
    const hers = await createInvite(request, zainab, planId, { rail: 'public' });
    expect(hers.code).not.toBe(a.code);
  });

  // V-INV-4
  test('codes', () => {
    for (let i = 0; i < 10_000; i++)
      expect(newInviteCode()).toMatch(/^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$/);
    expect(normaliseCode(' k7m-2qx ')).toBe('K7M2QX');
    expect(normaliseCode('K7M2Q')).toBeUndefined();
    expect(normaliseCode('K7M2Q0')).toBeUndefined();
  });
});

describe('viewing invites', () => {
  // V-VIEW-1 (FR-005, SEC-003)
  test('status precedence, public names, no invitee name or contact', async () => {
    const { activityId, planId } = await tundesPlan(1);
    const vouch = await createInvite(request, tunde, planId, {
      rail: 'vouch',
      inviteeName: 'Zainab Okafor',
      contact: newContact(),
      note: 'Sunset!',
    });
    const res = await viewInvite(request, vouch.code);
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const view = InviteView.parse(await res.json());
    expect(view).toMatchObject({
      status: 'claimable',
      rail: 'vouch',
      note: 'Sunset!',
      claimedByViewer: false,
    });
    expect(view.inviter.shortName).toBe('Tunde A.');
    // Sold out (Tunde took the only spot) shows on the activity, not as an invite status.
    expect(view.activity.status).toBe('sold_out');
    const text = JSON.stringify(view);
    expect(text).not.toContain('Zainab');
    expect(text).not.toContain('Adeyemi');
    expect(text).not.toContain('example.com');

    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    await request(`/api/invites/${pub.code}/pause`, { method: 'POST', headers: tunde.headers });
    const paused = InviteView.parse(await (await viewInvite(request, pub.code)).json());
    expect(paused).toMatchObject({ status: 'paused', pausedReason: 'owner', note: null });

    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${activityId}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    const expired = InviteView.parse(await (await viewInvite(request, pub.code)).json());
    expect(expired.status).toBe('expired');
  });

  test('a claimed vouch, seen by its claimer and by someone else', async () => {
    const { planId } = await tundesPlan();
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    expect((await claim(request, vouch.code, zainab)).status).toBe(201);
    const mine = InviteView.parse(await (await viewInvite(request, vouch.code, zainab.headers)).json());
    expect(mine).toMatchObject({ status: 'claimed', claimedByViewer: true });
    const other = InviteView.parse(await (await viewInvite(request, vouch.code, host.headers)).json());
    expect(other).toMatchObject({ status: 'claimed', claimedByViewer: false });
  });

  // V-VIEW-2 (FR-005)
  test('typed codes are normalised; short and unknown codes are invalid_code', async () => {
    const { planId } = await tundesPlan();
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const typed = `${pub.code.slice(0, 3).toLowerCase()}-${pub.code.slice(3)} `;
    expect((await viewInvite(request, encodeURIComponent(typed))).status).toBe(200);
    for (const bad of ['ABCDE', 'ZZZZZZ']) {
      const res = await viewInvite(request, bad);
      expect(res.status).toBe(404);
      expect(await errorCode(res)).toBe('invalid_code');
    }
  });
});

describe('open beacon', () => {
  async function opensOf(inviteId: string) {
    const [row] = await t.admin<
      { n: number }[]
    >`SELECT count(*)::int AS n FROM invite_opens WHERE invite_id = ${inviteId}`;
    return row!.n;
  }

  // V-OPEN-1 (FR-006)
  test('once per invite per device, with an invite_opened event', async () => {
    const { planId } = await tundesPlan();
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    const device = randomUUID();
    expect((await openInvite(request, vouch.code, device)).status).toBe(204);
    expect((await openInvite(request, vouch.code, device)).status).toBe(204);
    expect(await opensOf(vouch.id)).toBe(1);
    expect((await openInvite(request, vouch.code)).status).toBe(204);
    expect(await opensOf(vouch.id)).toBe(2);
    const [ev] = await t.admin<{ n: number }[]>`
      SELECT count(*)::int AS n FROM events WHERE name = 'invite_opened' AND invite_id = ${vouch.id}`;
    expect(ev!.n).toBe(2);
    const plan = (await (await request(`/api/plans/${planId}`, { headers: tunde.headers })).json()) as {
      invites: { id: string; status: string; opens: number }[];
    };
    expect(plan.invites.find((i) => i.id === vouch.id)).toMatchObject({ status: 'opened', opens: 2 });
  });

  // V-OPEN-2 (FR-006, AC-007)
  test('preview bots and the Plan’s own members are not recorded', async () => {
    const { planId } = await tundesPlan();
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    for (const ua of ['WhatsApp/2.23.20.0', 'Twitterbot/1.0', 'facebookexternalhit/1.1']) {
      expect((await openInvite(request, pub.code, randomUUID(), { 'user-agent': ua })).status).toBe(204);
    }
    expect((await openInvite(request, pub.code, randomUUID(), tunde.headers)).status).toBe(204);
    expect(await opensOf(pub.id)).toBe(0);
    // Someone outside the Plan who is signed in is recorded.
    expect((await openInvite(request, pub.code, randomUUID(), zainab.headers)).status).toBe(204);
    expect(await opensOf(pub.id)).toBe(1);
  });

  // V-OPEN-3 (FR-006)
  test('sold-out and expired invites are still recorded; a device ID is required', async () => {
    const { activityId, planId } = await tundesPlan(1);
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    await openInvite(request, pub.code);
    expect(await opensOf(pub.id)).toBe(1);
    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${activityId}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    await openInvite(request, pub.code);
    expect(await opensOf(pub.id)).toBe(2);
    const missing = await request(`/api/invites/${pub.code}/opens`, { method: 'POST' });
    expect(missing.status).toBe(400);
  });
});

describe('pausing', () => {
  // V-PAUSE-1 (FR-019)
  test('creator and host can pause and resume a public link; others cannot; vouches cannot', async () => {
    const { planId } = await tundesPlan();
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const pause = (caller: Caller, method = 'POST') =>
      request(`/api/invites/${pub.code}/pause`, { method, headers: caller.headers });
    const reason = async () =>
      (
        await t.admin<{ paused: boolean; paused_reason: string | null }[]>`
        SELECT paused, paused_reason FROM invite_controls WHERE invite_id = ${pub.id}`
      )[0];

    expect((await pause(tunde)).status).toBe(204);
    expect(await reason()).toEqual({ paused: true, paused_reason: 'owner' });
    const guest = { displayName: 'Kofi Mensah', contact: newContact() };
    const blocked = await claim(request, pub.code, guest);
    expect(blocked.status).toBe(409);
    expect(await errorCode(blocked)).toBe('invite_paused');

    expect((await pause(tunde, 'DELETE')).status).toBe(204);
    expect((await reason())!.paused).toBe(false);
    expect((await pause(host)).status).toBe(204);
    expect(await reason()).toEqual({ paused: true, paused_reason: 'host' });
    expect((await pause(zainab)).status).toBe(403);

    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    const v = await request(`/api/invites/${vouch.code}/pause`, { method: 'POST', headers: tunde.headers });
    expect(v.status).toBe(400);
  });
});

describe('rate limits', () => {
  // V-RL-1 (FR-017, AC-006)
  test('the 11th invalid code in an hour locks the device out of every code', async () => {
    const { planId } = await tundesPlan();
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const device = randomUUID();
    const headers = { 'x-device-id': device };
    for (let i = 0; i < 10; i++) expect((await viewInvite(request, 'ZZZZZZ', headers)).status).toBe(404);
    const locked = await viewInvite(request, 'ZZZZZZ', headers);
    expect(locked.status).toBe(429);
    expect(await errorCode(locked)).toBe('rate_limited');
    expect((await viewInvite(request, pub.code, headers)).status).toBe(429);
    expect((await openInvite(request, pub.code, device)).status).toBe(429);
    const c = await claim(
      request,
      pub.code,
      { displayName: 'Kofi', contact: newContact() },
      { deviceId: device },
    );
    expect(c.status).toBe(429);
    // Another device is unaffected; the locked one works again after the window.
    expect((await viewInvite(request, pub.code)).status).toBe(200);
    clock.advanceDays(1 / 24);
    expect((await viewInvite(request, pub.code, headers)).status).toBe(200);
  });

  // V-RL-2 (FR-018), with LINK_CLAIMS_PER_MINUTE = 3 in this file
  test('claim attempts per public link per minute', async () => {
    const { activityId, planId } = await tundesPlan(10);
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    clock.advanceDays(1 / 1440);
    const statuses: number[] = [];
    for (let i = 0; i < 4; i++) {
      statuses.push(
        (await claim(request, pub.code, { displayName: `Guest ${i}`, contact: newContact() })).status,
      );
    }
    expect(statuses).toEqual([201, 201, 201, 429]);
    const [row] = await t.admin<
      { spots_left: number }[]
    >`SELECT spots_left FROM activities WHERE id = ${activityId}`;
    expect(row!.spots_left).toBe(6);
    clock.advanceDays(1 / 1440);
    expect((await claim(request, pub.code, { displayName: 'Later', contact: newContact() })).status).toBe(
      201,
    );
  });

  // V-RL-3 (FR-018), with AUTO_PAUSE_MIN_OPENS = 20 in this file
  test('a busy public link with under 2% claims pauses itself', async () => {
    const quiet = await tundesPlan(10);
    const link = await createInvite(request, tunde, quiet.planId, { rail: 'public' });
    for (let i = 0; i < 19; i++) await openInvite(request, link.code);
    let control = await t.admin`SELECT paused FROM invite_controls WHERE invite_id = ${link.id}`;
    expect(control).toHaveLength(0);
    await openInvite(request, link.code);
    control =
      await t.admin`SELECT paused, paused_reason, paused_by FROM invite_controls WHERE invite_id = ${link.id}`;
    expect(control[0]).toEqual({ paused: true, paused_reason: 'auto', paused_by: null });

    // At 1 claim in 20 opens (5%), the link stays open.
    const busy = await tundesPlan(10);
    const ok = await createInvite(request, tunde, busy.planId, { rail: 'public' });
    clock.advanceDays(1 / 1440);
    expect((await claim(request, ok.code, { displayName: 'Kofi', contact: newContact() })).status).toBe(201);
    for (let i = 0; i < 20; i++) await openInvite(request, ok.code);
    expect(await t.admin`SELECT 1 FROM invite_controls WHERE invite_id = ${ok.id} AND paused`).toHaveLength(
      0,
    );
  });
});

// V-EVT-1 (FR-004, FR-013), creation and opens part; claims in claims.test.ts.
test('invite_created events carry user, activity, invite, rail and generation', async () => {
  const { planId } = await tundesPlan();
  const inv = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
  const [ev] = await t.admin`
    SELECT user_id, activity_id, invite_id, rail, generation FROM events
     WHERE name = 'invite_created' AND invite_id = ${inv.id}`;
  expect(ev).toMatchObject({ user_id: tunde.id, invite_id: inv.id, rail: 'vouch', generation: 0 });
});

// V-OBS-1 (NFR-003, SEC-004)
test('invite metrics carry only their listed labels', async () => {
  const { resourceMetrics } = await reader.collect();
  const all = resourceMetrics.scopeMetrics.flatMap((s) => s.metrics);
  const allowed: Record<string, string[]> = {
    invites_created_total: ['rail'],
    invite_opens_total: ['outcome', 'rail'],
    rate_limited_total: ['scope'],
    invite_auto_paused_total: [],
    booking_attempts_total: ['outcome', 'path'],
  };
  for (const [name, labels] of Object.entries(allowed)) {
    const m = all.find((x) => x.descriptor.name === name);
    expect(m).toBeDefined();
    for (const p of m!.dataPoints) expect(Object.keys(p.attributes).sort()).toEqual(labels);
  }
  const outcomes = all
    .find((x) => x.descriptor.name === 'invite_opens_total')!
    .dataPoints.map((p) => p.attributes.outcome);
  expect(new Set(outcomes)).toEqual(new Set(['recorded', 'duplicate', 'member', 'bot']));
  const claimOutcomes = all
    .find((x) => x.descriptor.name === 'booking_attempts_total')!
    .dataPoints.filter((p) => p.attributes.path === 'claim')
    .map((p) => p.attributes.outcome);
  expect(claimOutcomes).toEqual(expect.arrayContaining(['success', 'invite_paused', 'rate_limited']));
});
