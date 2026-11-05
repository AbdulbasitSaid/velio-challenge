import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { createDb, type Db } from '../../src/db/client';
import { createLogger } from '../../src/telemetry/logger';
import { TEST_PEPPER } from '../helpers/app';
import {
  bookOk,
  claim,
  createActivity,
  createInvite,
  errorCode,
  newContact,
  overHttp,
  signIn,
  signInMany,
  type Caller,
  type ClaimBody,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

// S4 V-CC-*: claims racing through a real Bun.serve and a pool of 20, as S2's last-spot test.
// Assertions are on outcomes, never timings.

const M = 200;
const ROUNDS = 3;

let t: TestDatabase;
let db: Db;
let server: ReturnType<typeof Bun.serve>;
let request: Requester;
let host: Caller;
let tunde: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  db = createDb(t.url, { max: 20 });
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
    // The per-link limit is checked elsewhere; here it must not interfere with the race.
    LINK_CLAIMS_PER_MINUTE: '100000',
    // Everyone gets invite tools: a random holdout user would get 403 creating the invite (S8).
    HOLDOUT_PERCENT: '0',
  });
  const app = createApp({ config, db, logger: createLogger('silent'), clock: () => new Date() });
  server = Bun.serve({ port: 0, fetch: app.fetch });
  request = overHttp(`http://localhost:${server.port}`);
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
}, 60_000);

afterAll(async () => {
  await server.stop(true);
  await db.destroy();
  await t.drop();
});

async function plan(capacity: number) {
  const a = await createActivity(request, host, { capacity });
  const booking = await bookOk(request, tunde, a.id);
  return { activityId: a.id, planId: booking.booking.planId };
}

async function audit(activityId: string) {
  return t.admin`SELECT table_name, first_bad_seq FROM audit_chain(${activityId})`;
}

async function chainSeqs(table: 'invites' | 'attributions', activityId: string) {
  const rows = await t.admin<{ s: number }[]>`
    SELECT chain_seq::int AS s FROM ${t.admin(table)} WHERE activity_id = ${activityId} ORDER BY chain_seq`;
  return rows.map((r) => r.s);
}

const range = (n: number) => Array.from({ length: n }, (_, i) => i + 1);

describe('claim races', () => {
  // V-CC-1 (FR-012, AC-001)
  test('20 people claim one vouch at once: exactly one gets it', async () => {
    const { activityId, planId } = await plan(10);
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    const people = await signInMany(request, 20, 'Racer');
    const results = await Promise.all(people.map((p) => claim(request, vouch.code, p)));
    const statuses = results.map((r) => r.status).sort();
    expect(statuses.filter((s) => s === 201)).toHaveLength(1);
    expect(statuses.filter((s) => s === 409)).toHaveLength(19);
    for (const r of results.filter((x) => x.status === 409))
      expect(await errorCode(r)).toBe('already_claimed');
    const [row] = await t.admin<{ spots_left: number; claims: number }[]>`
      SELECT spots_left, (SELECT count(*)::int FROM invite_claims WHERE invite_id = ${vouch.id}) AS claims
        FROM activities WHERE id = ${activityId}`;
    expect(row).toEqual({ spots_left: 8, claims: 1 });
  }, 30_000);

  // V-CC-2 (NFR-001, AC-003)
  for (const n of [1, 5, 14]) {
    test(`${M} new guests on a public link with ${n} spot(s): exactly ${n} claim, ${ROUNDS} rounds`, async () => {
      for (let round = 0; round < ROUNDS; round++) {
        // Tunde holds one spot, so capacity is n + 1.
        const { activityId, planId } = await plan(n + 1);
        const pub = await createInvite(request, tunde, planId, { rail: 'public' });
        const results = await Promise.all(
          Array.from({ length: M }, (_, i) =>
            claim(request, pub.code, { displayName: `Guest ${i}`, contact: newContact() }),
          ),
        );
        const ok = results.filter((r) => r.status === 201);
        expect(ok).toHaveLength(n);
        for (const r of results.filter((x) => x.status !== 201)) {
          expect(r.status).toBe(409);
          expect(await errorCode(r)).toBe('sold_out');
        }
        const [row] = await t.admin<{ spots_left: number; users: number }[]>`
          SELECT spots_left,
                 (SELECT count(*)::int FROM users WHERE display_name LIKE 'Guest %'
                    AND id IN (SELECT user_id FROM bookings WHERE activity_id = ${activityId})) AS users
            FROM activities WHERE id = ${activityId}`;
        expect(row!.spots_left).toBe(0);
        expect(row!.users).toBe(n);
        expect(await chainSeqs('attributions', activityId)).toEqual(range(n));
        expect(await audit(activityId)).toHaveLength(0);
      }
    }, 60_000);
  }

  // V-CC-3
  test('one new contact claiming 10 times at once creates one user and one booking', async () => {
    const { activityId, planId } = await plan(20);
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const contact = newContact();
    const sameKey = randomUUID();
    const a = await Promise.all(
      Array.from({ length: 10 }, () =>
        claim(request, pub.code, { displayName: 'Same Person', contact }, { key: sameKey }),
      ),
    );
    expect(a.filter((r) => r.status === 201)).toHaveLength(1);
    expect(a.filter((r) => r.status === 200)).toHaveLength(9);
    const ids = new Set(await Promise.all(a.map(async (r) => ((await r.json()) as ClaimBody).booking.id)));
    expect(ids.size).toBe(1);

    const other = newContact();
    const b = await Promise.all(
      Array.from({ length: 10 }, () =>
        claim(request, pub.code, { displayName: 'Other Person', contact: other }),
      ),
    );
    expect(b.filter((r) => r.status === 201)).toHaveLength(1);
    for (const r of b.filter((x) => x.status !== 201)) {
      expect(r.status).toBe(409);
      expect(await errorCode(r)).toBe('already_booked');
    }
    const [row] = await t.admin<{ users: number; bookings: number }[]>`
      SELECT (SELECT count(*)::int FROM users WHERE display_name IN ('Same Person', 'Other Person')) AS users,
             (SELECT count(*)::int FROM bookings WHERE activity_id = ${activityId}) AS bookings`;
    expect(row).toEqual({ users: 2, bookings: 3 });
  }, 30_000);

  // V-CC-4
  test('invite creation racing claims keeps both chains intact', async () => {
    const { activityId, planId } = await plan(60);
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const [creations, claims] = await Promise.all([
      Promise.all(
        Array.from({ length: 20 }, (_, i) =>
          createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: `Friend ${i}` }),
        ),
      ),
      Promise.all(
        Array.from({ length: 50 }, (_, i) =>
          claim(request, pub.code, { displayName: `Racer ${i}`, contact: newContact() }),
        ),
      ),
    ]);
    expect(creations).toHaveLength(20);
    expect(claims.every((r) => r.status === 201)).toBe(true);
    expect(await chainSeqs('invites', activityId)).toEqual(range(21));
    expect(await chainSeqs('attributions', activityId)).toEqual(range(50));
    expect(await audit(activityId)).toHaveLength(0);
  }, 30_000);
});
