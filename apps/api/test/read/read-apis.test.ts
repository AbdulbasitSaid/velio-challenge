import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { Kysely } from 'kysely';
import { PostgresJSDialect } from 'kysely-postgres-js';
import postgres from 'postgres';
import {
  Attendance,
  CommunityList,
  CommunityPage,
  HostActivityList,
  MyPlans,
  NextSteps,
  Profile,
} from '@velio/contracts';
import type { DB } from '../../src/db/types';
import { createAttendanceService } from '../../src/modules/attendance/service';
import { createCommunityService } from '../../src/modules/communities/service';
import { createPlanService } from '../../src/modules/plans/service';
import { loadConfig } from '../../src/config';
import { json, TEST_PEPPER, testApp } from '../helpers/app';
import {
  bookOk,
  claim,
  createActivity,
  createInvite,
  errorCode,
  inProcess,
  newContact,
  removeBooking,
  signIn,
  type Caller,
  type ClaimBody,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;
let request: Requester;
let host: Caller;
let tunde: Caller;
let zainab: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db));
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
  zainab = await signIn(request, 'Zainab Okafor');
});

afterAll(async () => {
  await t.drop();
});

/** Moves an activity into the past. Its date is locked once booked, so the test lifts the lock. */
async function startNow(activityId: string, ago = '1 minute') {
  await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
  await t.admin`UPDATE activities SET starts_at = now() - ${ago}::interval WHERE id = ${activityId}`;
  await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
}

const get = async (path: string, caller?: Caller) => request(path, { headers: caller?.headers ?? {} });

describe('GET /api/me/plans', () => {
  // V-READ-1 (FR-022)
  test('upcoming soonest first, past most recent first, removed included; own ref only', async () => {
    const me = await signIn(request, 'Planner Person');
    const soon = await createActivity(request, host, {
      startsAt: new Date(Date.now() + 2 * 86_400_000).toISOString(),
    });
    const later = await createActivity(request, host, {
      startsAt: new Date(Date.now() + 9 * 86_400_000).toISOString(),
    });
    const old1 = await createActivity(request, host);
    const old2 = await createActivity(request, host);
    const b1 = await bookOk(request, me, later.id);
    await bookOk(request, me, soon.id);
    await bookOk(request, me, old1.id);
    await bookOk(request, me, old2.id);
    await bookOk(request, tunde, later.id);
    await startNow(old1.id, '2 days');
    await startNow(old2.id, '1 day');
    await removeBooking(request, host, b1.booking.id);

    const res = await get('/api/me/plans', me);
    const body = MyPlans.parse(await res.json());
    expect(body.upcoming.map((p) => p.activity.id)).toEqual([soon.id, later.id]);
    expect(body.past.map((p) => p.activity.id)).toEqual([old2.id, old1.id]);
    const removed = body.upcoming[1]!;
    expect(removed.booking).toEqual({ id: b1.booking.id, ref: b1.booking.ref, status: 'removed' });
    // Members of that Plan: only confirmed ones (me was removed), as MemberPerson.
    expect(removed.members.count).toBe(0);
    expect(JSON.stringify(body)).not.toContain('VLO-' + 'X'.repeat(5));
    expect((await get('/api/me/plans')).status).toBe(401);
  });
});

describe('GET /api/host/activities', () => {
  // V-READ-2 (FR-023)
  test('upcoming and past with bookedCount; empty for a non-host', async () => {
    const h = await signIn(request, 'Second Host');
    const up = await createActivity(request, h, { capacity: 4 });
    const past = await createActivity(request, h, { capacity: 4 });
    await bookOk(request, tunde, up.id);
    await bookOk(request, zainab, up.id);
    await startNow(past.id);
    const body = HostActivityList.parse(await (await get('/api/host/activities', h)).json());
    expect(body.upcoming.map((a) => [a.id, a.bookedCount, a.spotsLeft])).toEqual([[up.id, 2, 2]]);
    expect(body.past.map((a) => [a.id, a.status])).toEqual([[past.id, 'started']]);
    const none = HostActivityList.parse(await (await get('/api/host/activities', zainab)).json());
    expect(none).toEqual({ upcoming: [], past: [] });
  });

  // V-HOST-1 (S5 FR-032): "Mark attendance" until someone is marked, then "{n} attended".
  test('past rows count marks by the latest mark, confirmed bookings only', async () => {
    const h = await signIn(request, 'Marking Host');
    const a = await createActivity(request, h, { capacity: 5 });
    const people = await Promise.all(['One', 'Two', 'Three'].map((n) => signIn(request, `Guest ${n}`)));
    const [b1, b2, b3] = await Promise.all(people.map((p) => bookOk(request, p, a.id)));
    await startNow(a.id);
    const items = async () =>
      HostActivityList.parse(await (await get('/api/host/activities', h)).json()).past.map((p) => [
        p.markedCount,
        p.attendedCount,
      ]);
    expect(await items()).toEqual([[0, 0]]);
    const mark = (id: string, m: string) =>
      request(`/api/host/bookings/${id}/attendance`, json({ mark: m }, h.headers));
    await mark(b1!.booking.id, 'attended');
    await mark(b2!.booking.id, 'attended');
    await mark(b2!.booking.id, 'no_show');
    expect(await items()).toEqual([[2, 1]]);
    await mark(b3!.booking.id, 'attended');
    expect((await removeBooking(request, h, b3!.booking.id)).status).toBe(200);
    expect(await items()).toEqual([[2, 1]]);
  });
});

describe('attendance', () => {
  // V-READ-3 (FR-024, SEC-007)
  test('the host sees names, refs, sources and inviters; nobody else can', async () => {
    const a = await createActivity(request, host, { capacity: 6 });
    const tb = await bookOk(request, tunde, a.id);
    const vouch = await createInvite(request, tunde, tb.booking.planId, {
      rail: 'vouch',
      inviteeName: 'Zainab',
      contact: newContact(),
      note: 'Private note',
    });
    const zc = (await (await claim(request, vouch.code, zainab)).json()) as ClaimBody;
    const pub = await createInvite(request, tunde, tb.booking.planId, { rail: 'public' });
    const guestContact = newContact();
    const gc = (await (
      await claim(request, pub.code, { displayName: 'Kofi Mensah', contact: guestContact })
    ).json()) as ClaimBody;
    await removeBooking(request, host, gc.booking.id);

    const res = await get(`/api/host/activities/${a.id}/attendance`, host);
    expect(res.status).toBe(200);
    const text = await res.clone().text();
    const body = Attendance.parse(JSON.parse(text));
    expect(body.activity).toMatchObject({ id: a.id, capacity: 6, spotsLeft: 4, started: false });
    expect(
      body.attendees.map((x) => [x.person.displayName, x.source, x.invitedBy?.displayName ?? null, x.status]),
    ).toEqual([
      ['Tunde Adeyemi', 'direct', null, 'confirmed'],
      ['Zainab Okafor', 'vouch', 'Tunde Adeyemi', 'confirmed'],
      ['Kofi Mensah', 'public', 'Tunde Adeyemi', 'removed'],
    ]);
    expect(body.attendees[1]!.ref).toBe(zc.booking.ref);
    expect(text).not.toContain('Private note');
    expect(text).not.toContain(guestContact);
    expect(text).not.toMatch(/contact|hash|note/i);

    expect((await get(`/api/host/activities/${a.id}/attendance`, tunde)).status).toBe(403);
    expect((await get(`/api/host/activities/${randomUUID()}/attendance`, host)).status).toBe(404);
  });

  // V-READ-4 (FR-025, AC-009)
  test('marks: after start, latest wins, both kept; not on removed bookings; host only', async () => {
    const a = await createActivity(request, host, { capacity: 4 });
    const tb = await bookOk(request, tunde, a.id);
    const zb = await bookOk(request, zainab, a.id);
    const mark = (id: string, m: string, caller = host) =>
      request(`/api/host/bookings/${id}/attendance`, json({ mark: m }, caller.headers));

    const early = await mark(tb.booking.id, 'attended');
    expect([early.status, await errorCode(early)]).toEqual([409, 'activity_not_started']);

    await removeBooking(request, host, zb.booking.id);
    await startNow(a.id);
    expect((await mark(tb.booking.id, 'no_show')).status).toBe(200);
    const final = await mark(tb.booking.id, 'attended');
    expect(final.status).toBe(200);
    expect(((await final.json()) as { mark: string }).mark).toBe('attended');
    const marks =
      await t.admin`SELECT mark FROM attendance_marks WHERE booking_id = ${tb.booking.id} ORDER BY created_at, id`;
    expect([...marks]).toEqual([{ mark: 'no_show' }, { mark: 'attended' }]);
    const list = Attendance.parse(await (await get(`/api/host/activities/${a.id}/attendance`, host)).json());
    expect(list.attendees.find((x) => x.bookingId === tb.booking.id)!.mark).toBe('attended');

    const removed = await mark(zb.booking.id, 'attended');
    expect([removed.status, await errorCode(removed)]).toEqual([409, 'booking_removed']);
    expect((await mark(tb.booking.id, 'attended', tunde)).status).toBe(403);
    expect((await mark(tb.booking.id, 'maybe')).status).toBe(400);
  });
});

describe('communities, profiles, next-steps', () => {
  // V-READ-5 (FR-026, FR-029)
  test('community list and page: upcoming only, soonest first, sold out included', async () => {
    const h = await signIn(request, 'Community Host');
    const open = await createActivity(request, h, {
      communitySlug: 'the-medina-collective',
      startsAt: new Date(Date.now() + 5 * 86_400_000).toISOString(),
      description: `  Spice   route\n\nwalk. ${'word '.repeat(40)}`,
    });
    const soldOut = await createActivity(request, h, {
      communitySlug: 'the-medina-collective',
      capacity: 1,
      startsAt: new Date(Date.now() + 3 * 86_400_000).toISOString(),
    });
    const past = await createActivity(request, h, { communitySlug: 'the-medina-collective' });
    await bookOk(request, tunde, soldOut.id);
    await startNow(past.id);

    const list = CommunityList.parse(await (await get('/api/communities')).json());
    expect(list.communities.find((c) => c.slug === 'the-medina-collective')!.upcomingCount).toBe(2);
    const page = CommunityPage.parse(await (await get('/api/communities/the-medina-collective')).json());
    expect(page.activities.map((a) => [a.id, a.status])).toEqual([
      [soldOut.id, 'sold_out'],
      [open.id, 'open'],
    ]);
    expect(page.activities[0]!.location).toMatchObject({ lat: expect.any(Number), lng: expect.any(Number) });
    expect(page.activities[0]!.members.preview[0]!.shortName).toBe('Tunde A.');
    // Explore map preview FR-001, FR-002
    expect(page.activities[1]!.summary).toBe(`Spice route walk. ${'word '.repeat(23)}word…`);
    expect(JSON.stringify(page)).not.toContain('Adeyemi');
    expect((await get('/api/communities/nowhere')).status).toBe(404);
  });

  // V-READ-6 (FR-027, AC-010)
  test('profile: public name, member since, upcoming hosted only, never bookings', async () => {
    const h = await signIn(request, 'Profile Person');
    const hosted = await createActivity(request, h);
    const ended = await createActivity(request, h);
    await startNow(ended.id);
    const elsewhere = await createActivity(request, host);
    await bookOk(request, h, elsewhere.id);
    const p = Profile.parse(await (await get(`/api/users/${h.id}/profile`)).json());
    expect(p.person).toEqual({ id: h.id, shortName: 'Profile P.', avatarSeed: h.id });
    expect(p.memberSince).toMatch(/^\d{4}-\d{2}$/);
    expect(p.hosting.map((a) => a.id)).toEqual([hosted.id]);
    expect(JSON.stringify(p)).not.toContain(elsewhere.id);
    expect((await get(`/api/users/${randomUUID()}/profile`)).status).toBe(404);
  });

  // V-READ-7 (FR-028)
  test('next-steps: at most 3 each, with spots, soonest first, excluding this one', async () => {
    const h = await signIn(request, 'Busy Host');
    const day = (n: number) => new Date(Date.now() + n * 86_400_000).toISOString();
    const current = await createActivity(request, h, {
      communitySlug: 'the-tanzania-experience',
      startsAt: day(1),
    });
    const mine = [];
    for (let i = 2; i <= 6; i++) {
      mine.push(
        await createActivity(request, h, {
          communitySlug: 'the-tanzania-experience',
          startsAt: day(i),
          capacity: 1,
        }),
      );
    }
    // Sell out the two soonest other dates.
    await bookOk(request, tunde, mine[0]!.id);
    await bookOk(request, tunde, mine[1]!.id);
    const body = NextSteps.parse(await (await get(`/api/activities/${current.id}/next-steps`)).json());
    expect(body.hostOtherDates.map((a) => a.id)).toEqual([mine[2]!.id, mine[3]!.id, mine[4]!.id]);
    expect(body.moreInCommunity).toHaveLength(3);
    expect(body.moreInCommunity.every((a) => a.spotsLeft > 0 && a.id !== current.id)).toBe(true);
    expect((await get(`/api/activities/${randomUUID()}/next-steps`)).status).toBe(404);
  });
});

// V-READ-8 (NFR-005): the same number of queries at 1 and at 20 rows.
describe('query counts', () => {
  test('list endpoints run a fixed number of queries', async () => {
    const queries: string[] = [];
    const sql = postgres(t.url, { max: 1, onnotice: () => {} });
    const counted = new Kysely<DB>({
      dialect: new PostgresJSDialect({ postgres: sql }),
      log: () => {
        queries.push('q');
      },
    });
    const config = loadConfig({
      NODE_ENV: 'test',
      DATABASE_URL: t.url,
      DATABASE_LISTEN_URL: t.url,
      CONTACT_PEPPER: TEST_PEPPER,
    });
    const plans = createPlanService(counted, config);
    const attendance = createAttendanceService(counted);
    const communities = createCommunityService(counted);
    const count = async (fn: () => Promise<unknown>) => {
      queries.length = 0;
      await fn();
      return queries.length;
    };
    try {
      const small = await signIn(request, 'Small Lister');
      const big = await signIn(request, 'Big Lister');
      const one = await createActivity(request, host, { communitySlug: 'explore-kenya' });
      await bookOk(request, small, one.id);
      // With nothing to list, the card queries are skipped: fewer, never more. Compare like with like.
      await createActivity(request, small);
      for (let i = 0; i < 20; i++) {
        const a = await createActivity(request, big, { capacity: 3 });
        const g = await signIn(request, `Lister Guest ${i}`);
        await bookOk(request, g, a.id);
        const other = await createActivity(request, host);
        await bookOk(request, big, other.id);
      }
      expect(await count(() => plans.mine(big.id))).toBe(await count(() => plans.mine(small.id)));
      expect(await count(() => attendance.hosted(big.id))).toBe(
        await count(() => attendance.hosted(host.id)),
      );
      expect(await count(() => communities.profile(big.id))).toBe(
        await count(() => communities.profile(small.id)),
      );
      const n = await count(() => communities.page('explore-kenya'));
      expect(n).toBeLessThanOrEqual(4);
    } finally {
      await counted.destroy();
    }
  }, 60_000);
});
