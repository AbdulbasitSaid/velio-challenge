// S8 admin (V: T5, T6): the views on a hand-computed scenario, the admin metrics endpoint, the
// token guard, the kill switch and the on-demand audit.
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { AdminActivityList, AdminAudit, AdminMetrics, PlanView } from '@velio/contracts';
import { armOf } from '../../src/modules/flags/holdout';
import { json, testApp } from '../helpers/app';
import {
  book,
  bookOk,
  claim,
  createActivity,
  createInvite,
  errorCode,
  inProcess,
  newContact,
  openInvite,
  removeBooking,
  signIn,
  type Caller,
  type ClaimBody,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

const TOKEN = 'admin-token-for-tests-0123456789abcdef';
const HOLDOUT = 50;

let t: TestDatabase;
let request: Requester;
const admin = { authorization: `Bearer ${TOKEN}` };

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db, undefined, { ADMIN_TOKEN: TOKEN, HOLDOUT_PERCENT: String(HOLDOUT) }));
});

afterAll(async () => {
  await t.drop();
});

/** Signs people in until one lands in `arm` (the arm is a hash of the new user's ID). */
async function signInAs(arm: 'exposed' | 'holdout', name: string): Promise<Caller> {
  for (;;) {
    const caller = await signIn(request, name);
    if (armOf(caller.id, HOLDOUT) === arm) return caller;
  }
}

const getMetrics = async () => {
  const res = await request('/api/admin/metrics?days=7', { headers: admin });
  expect(res.status).toBe(200);
  return AdminMetrics.parse(await res.json());
};

// FR-008, FR-009, AC-005, SEC-002
describe('metrics on a seeded scenario', () => {
  test('every figure matches the hand count', async () => {
    const host = await signIn(request, 'Amara Host');
    const e1 = await signInAs('exposed', 'Tunde Exposed');
    const e2 = await signInAs('exposed', 'Imani Exposed');
    const x1 = await signInAs('holdout', 'Kofi Holdout');
    const organic = await signIn(request, 'Zainab Organic');
    const a = await createActivity(request, host, { capacity: 10 });

    const plans = new Map<string, string>();
    for (const c of [e1, e2, x1]) {
      const { booking } = await bookOk(request, c, a.id);
      plans.set(c.id, booking.planId);
      const plan = PlanView.parse(
        await (await request(`/api/plans/${booking.planId}`, { headers: c.headers })).json(),
      );
      expect(plan.viewer.canInvite).toBe(c !== x1);
    }

    // e1 invites on both rails: the vouch is opened twice and claimed by a new guest; the public link
    // is opened four times and claimed by a new guest and by someone already on Velio.
    const vouch = await createInvite(request, e1, plans.get(e1.id)!, {
      rail: 'vouch',
      inviteeName: 'Guest One',
      contact: newContact(),
    });
    const pub = await createInvite(request, e1, plans.get(e1.id)!, { rail: 'public' });
    for (let i = 0; i < 2; i++) expect((await openInvite(request, vouch.code)).status).toBe(204);
    for (let i = 0; i < 4; i++) expect((await openInvite(request, pub.code)).status).toBe(204);
    const claimed = async (code: string, as: Parameters<typeof claim>[2]) => {
      const res = await claim(request, code, as);
      expect(res.status).toBe(201);
      return (await res.json()) as ClaimBody;
    };
    const g1 = await claimed(vouch.code, { displayName: 'Guest One', contact: newContact() });
    const g2 = await claimed(pub.code, { displayName: 'Guest Two', contact: newContact() });
    const o = await claimed(pub.code, organic);

    // The host removes the organic claimer before the start; one server error is recorded.
    expect((await removeBooking(request, host, o.booking.id)).status).toBe(200);
    await t.admin`INSERT INTO events (name, activity_id) VALUES ('booking_failed', ${a.id})`;

    // After the start: e1's Plan all attended (e1, g1, g2); e2 a no-show; x1 unmarked.
    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${a.id}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    const bookingOf = async (userId: string) =>
      (
        await t.admin<
          { id: string }[]
        >`SELECT id FROM bookings WHERE activity_id = ${a.id} AND user_id = ${userId}`
      )[0]!.id;
    const mark = async (bookingId: string, m: 'attended' | 'no_show') =>
      expect(
        (await request(`/api/host/bookings/${bookingId}/attendance`, json({ mark: m }, host.headers))).status,
      ).toBe(200);
    await mark(await bookingOf(e1.id), 'attended');
    await mark(g1.booking.id, 'attended');
    await mark(g2.booking.id, 'attended');
    await mark(await bookingOf(e2.id), 'no_show');

    const m = await getMetrics();
    const goal = (id: string) => m.goals.find((g) => g.id === id)!;
    expect(goal('no_oversell')).toMatchObject({ value: 0, triggered: false });
    // Six bookings (three direct, three claims) and one server error.
    expect(goal('booking_success')).toMatchObject({ value: 6 / 7, sample: 7 });
    expect(goal('availability_live')).toMatchObject({ value: null, sample: 0, triggered: false });
    // Exposed bookers: e1 invited, e2 didn't. x1 is holdout; the guests never reached an invite surface.
    expect(goal('bookers_invite')).toMatchObject({ value: 0.5, sample: 2, triggered: false });
    expect(goal('invites_convert_vouch')).toMatchObject({ value: 0.5, sample: 2, triggered: false });
    expect(goal('invites_convert_public')).toMatchObject({
      value: 0.5,
      sample: 4,
      target: null,
      triggered: false,
    });

    expect(m.funnel).toEqual([
      {
        rail: 'vouch',
        invites: 1,
        opens: 2,
        claims: 1,
        openToClaim: { numerator: 1, denominator: 2, value: 0.5 },
      },
      {
        rail: 'public',
        invites: 1,
        opens: 4,
        claims: 2,
        openToClaim: { numerator: 2, denominator: 4, value: 0.5 },
      },
    ]);
    expect(m.blendedOpenToClaim.value).toBe(0.5);
    expect(m.inviteRate.map((r) => [r.rail, r.rate.value])).toEqual([
      ['any', 0.5],
      ['vouch', 0.5],
      ['public', 0.5],
    ]);
    // The organic claimer was already on Velio, so only g1 and g2 are new users.
    expect(m.kFactor).toEqual([
      { rail: 'vouch', newUsers: 1, inviters: 1, value: 1 },
      { rail: 'public', newUsers: 1, inviters: 1, value: 1 },
    ]);
    // Plans that reached the start: e1's (happened), e2's and x1's (didn't).
    expect(m.plansHappened).toEqual({ numerator: 1, denominator: 3, value: 1 / 3 });
    // Invited: g1, g2, o (removed). Organic: e1, e2 (no-show), x1.
    expect(m.guardrail).toEqual({
      invited: { numerator: 1, denominator: 3, value: 1 / 3 },
      organic: { numerator: 1, denominator: 3, value: 1 / 3 },
      ratio: 1,
      triggered: false,
    });
    expect(m.holdout).toEqual([
      {
        arm: 'exposed',
        users: 2,
        bookers: 2,
        newUsersPerBooker: { numerator: 2, denominator: 2, value: 1 },
        plansHappened: { numerator: 1, denominator: 2, value: 0.5 },
      },
      {
        arm: 'holdout',
        users: 1,
        bookers: 1,
        newUsersPerBooker: { numerator: 0, denominator: 1, value: 0 },
        plansHappened: { numerator: 0, denominator: 1, value: 0 },
      },
    ]);
    // Aggregates only: no names, contacts or codes (SEC-002).
    const raw = JSON.stringify(m);
    for (const s of ['Tunde', 'Guest', 'example.com', vouch.code, pub.code]) expect(raw).not.toContain(s);
  });
});

// FR-010, AC-006, SEC-001
describe('admin token', () => {
  test('404 when no token is configured', async () => {
    const off = inProcess(testApp(t.db));
    expect((await off('/api/admin/metrics', { headers: admin })).status).toBe(404);
  });

  test('401 without or with a wrong token; 429 after 10 wrong tokens in a minute', async () => {
    const fixed = inProcess(testApp(t.db, () => new Date('2026-11-05T12:00:30Z'), { ADMIN_TOKEN: TOKEN }));
    const ip = { 'x-forwarded-for': `10.0.0.${Math.floor(Math.random() * 200) + 1}` };
    expect((await fixed('/api/admin/metrics', { headers: ip })).status).toBe(401);
    for (let i = 0; i < 9; i++) {
      const res = await fixed('/api/admin/metrics', { headers: { ...ip, authorization: 'Bearer wrong' } });
      expect(res.status).toBe(401);
      expect(await errorCode(res)).toBe('unauthenticated');
    }
    const locked = await fixed('/api/admin/metrics', { headers: { ...ip, ...admin } });
    expect(locked.status).toBe(429);
  });
});

// FR-011, FR-012, AC-006
describe('kill switch', () => {
  test('pause refuses bookings, resume allows them; both listed and repeatable', async () => {
    const host = await signIn(request, 'Amara Host');
    const guest = await signIn(request, 'Guest Booker');
    const a = await createActivity(request, host);
    const pause = (action: string) =>
      request(`/api/admin/activities/${a.id}/${action}`, { method: 'POST', headers: admin });

    expect((await pause('pause')).status).toBe(204);
    expect((await pause('pause')).status).toBe(204);
    const list = AdminActivityList.parse(
      await (await request('/api/admin/activities', { headers: admin })).json(),
    );
    expect(list.activities.find((x) => x.id === a.id)).toMatchObject({ bookingsPaused: true, spotsLeft: 14 });
    const refused = await book(request, guest, a.id);
    expect(refused.status).toBe(409);
    expect(await errorCode(refused)).toBe('bookings_paused');

    expect((await pause('resume')).status).toBe(204);
    expect((await book(request, guest, a.id)).status).toBe(201);
    expect(
      (await request(`/api/admin/activities/${randomUUID()}/pause`, { method: 'POST', headers: admin }))
        .status,
    ).toBe(404);
  });
});

// FR-013
describe('audit', () => {
  test('on demand: intact chains report no failures, and the metrics show the run', async () => {
    const res = await request('/api/admin/audit', { method: 'POST', headers: admin });
    expect(res.status).toBe(200);
    expect(AdminAudit.parse(await res.json()).failures).toEqual([]);
    expect((await getMetrics()).audit).toMatchObject({ failures: 0, ranAt: expect.any(String) });
  });
});
