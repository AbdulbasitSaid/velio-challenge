import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { PlanView } from '@velio/contracts';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { createDb, type Db } from '../../src/db/client';
import { createRealtime, type Realtime } from '../../src/modules/realtime/gateway';
import { createLogger } from '../../src/telemetry/logger';
import { TEST_PEPPER } from '../helpers/app';
import {
  bookOk,
  claim,
  createActivity,
  createInvite,
  newContact,
  openInvite,
  overHttp,
  removeBooking,
  signIn,
  type Caller,
  type ClaimBody,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';
import { connectWs } from '../helpers/ws';

let t: TestDatabase;
let db: Db;
let realtime: Realtime;
let server: ReturnType<typeof Bun.serve>;
let base: string;
let request: Requester;
let host: Caller;
let tunde: Caller;
let zainab: Caller;
let kofi: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  db = createDb(t.url, { max: 10 });
  const logger = createLogger('silent');
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
    PUBLIC_BASE_URL: 'https://d1.cloudfront.net',
  });
  realtime = createRealtime({ db, logger, listenUrl: t.url });
  const app = createApp({ config, db, logger, clock: () => new Date(), realtime });
  server = Bun.serve({ port: 0, fetch: app.fetch, websocket: realtime.websocket });
  realtime.attach(server);
  await realtime.start();
  base = `http://localhost:${server.port}`;
  request = overHttp(base);
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
  zainab = await signIn(request, 'Zainab Okafor');
  kofi = await signIn(request, 'Kofi Mensah');
}, 30_000);

afterAll(async () => {
  realtime.closeSockets();
  await server.stop(true);
  await realtime.stop();
  await db.destroy();
  await t.drop();
});

async function planAs(caller: Caller, planId: string) {
  const res = await request(`/api/plans/${planId}`, { headers: caller.headers });
  return { res, body: res.status === 200 ? PlanView.parse(await res.json()) : undefined };
}

describe('GET /api/plans/:id', () => {
  // V-PLAN-1 (FR-020, SEC-002, SEC-003)
  test('by audience: owner, claimed guest, removed member, outsider', async () => {
    const a = await createActivity(request, host, { capacity: 5 });
    const tb = await bookOk(request, tunde, a.id);
    const planId = tb.booking.planId;
    const vouch = await createInvite(request, tunde, planId, {
      rail: 'vouch',
      inviteeName: 'Zainab',
      note: 'Just for you',
    });
    const zc = (await (await claim(request, vouch.code, zainab)).json()) as ClaimBody;
    const pub = await createInvite(request, zainab, planId, { rail: 'public' });

    const owner = (await planAs(tunde, planId)).body!;
    expect(owner.owner.displayName).toBe('Tunde Adeyemi');
    expect(
      owner.members.map((m) => [m.person.displayName, m.source, m.invitedBy?.displayName ?? null]),
    ).toEqual([
      ['Tunde Adeyemi', 'direct', null],
      ['Zainab Okafor', 'vouch', 'Tunde Adeyemi'],
    ]);
    expect(owner.viewer).toEqual({
      booking: { id: tb.booking.id, ref: tb.booking.ref, status: 'confirmed' },
      canInvite: true,
    });
    const ownVouch = owner.invites.find((i) => i.id === vouch.id)!;
    expect(ownVouch).toMatchObject({
      code: vouch.code,
      note: 'Just for you',
      status: 'claimed',
      inviteeName: 'Zainab',
    });
    const hersSeenByTunde = owner.invites.find((i) => i.id === pub.id)!;
    expect(hersSeenByTunde.code).toBeUndefined();
    expect(hersSeenByTunde.link).toBeUndefined();
    expect(hersSeenByTunde.note).toBeUndefined();

    const guest = (await planAs(zainab, planId)).body!;
    expect(guest.viewer.booking.ref).toBe(zc.booking.ref);
    expect(guest.invites.find((i) => i.id === vouch.id)!.note).toBeUndefined();
    expect(guest.invites.find((i) => i.id === pub.id)!.code).toBe(pub.code);
    // Nobody else's booking reference.
    expect(JSON.stringify(guest)).not.toContain(tb.booking.ref);

    await removeBooking(request, host, zc.booking.id);
    const removed = (await planAs(zainab, planId)).body!;
    expect(removed.viewer).toEqual({
      booking: { id: zc.booking.id, ref: zc.booking.ref, status: 'removed' },
      canInvite: false,
    });
    expect(removed.invites).toEqual([]);
    expect(removed.members.map((m) => m.person.id)).toEqual([tunde.id]);

    expect((await planAs(kofi, planId)).res.status).toBe(403);
    expect((await planAs(kofi, '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f')).res.status).toBe(404);
  });

  // V-PLAN-2 (FR-020): invite status through the lifecycle
  test('invite status: created, opened, claimed, expired', async () => {
    const a = await createActivity(request, host, { capacity: 6 });
    const planId = (await bookOk(request, tunde, a.id)).booking.planId;
    const v = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Ada' });
    const p = await createInvite(request, tunde, planId, { rail: 'public' });
    const status = async (id: string) =>
      (await planAs(tunde, planId)).body!.invites.find((i) => i.id === id)!;

    expect((await status(v.id)).status).toBe('created');
    await openInvite(request, v.code);
    expect((await status(v.id)).status).toBe('opened');
    await claim(request, v.code, { displayName: 'Ada Obi', contact: newContact() });
    expect((await status(v.id)).status).toBe('claimed');

    await openInvite(request, p.code);
    expect(await status(p.id)).toMatchObject({ status: 'opened', opens: 1, claims: 0 });
    await claim(request, p.code, { displayName: 'Public One', contact: newContact() });
    await openInvite(request, p.code);
    expect(await status(p.id)).toMatchObject({ status: 'claimed', opens: 2, claims: 1 });

    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${a.id}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    expect((await status(p.id)).status).toBe('expired');
    // A claimed vouch stays claimed after the start.
    expect((await status(v.id)).status).toBe('claimed');
    expect((await planAs(tunde, planId)).body!.viewer.canInvite).toBe(false);
  });

  // V-PLAN-3 (FR-004, FR-006, FR-019): live through the S3 Plan topic
  test('create, open, claim and pause each send a plan hint', async () => {
    const a = await createActivity(request, host, { capacity: 6 });
    const planId = (await bookOk(request, tunde, a.id)).booking.planId;
    const ws = await connectWs(base, { headers: tunde.headers });
    const done = ws.waitFor((m) => m.type === 'subscribed');
    ws.send({ type: 'subscribe', topics: [`plan:${planId}`] });
    await done;
    const hints = () => ws.messages.filter((m) => m.type === 'plan').length;
    const expectHints = async (n: number) => {
      for (let i = 0; i < 50 && hints() < n; i++) await Bun.sleep(20);
      expect(hints()).toBe(n);
    };

    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    await expectHints(1);
    await openInvite(request, pub.code);
    await expectHints(2);
    await claim(request, pub.code, { displayName: 'Live Guest', contact: newContact() });
    await expectHints(3);
    await request(`/api/invites/${pub.code}/pause`, { method: 'POST', headers: tunde.headers });
    await expectHints(4);
    ws.close();
  });
});
