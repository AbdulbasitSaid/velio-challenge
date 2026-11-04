import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { ClaimResponse } from '@velio/contracts';
import { sessionCookie, testApp } from '../helpers/app';
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
/** Every response body in this file, for the AC-008 scan. */
const bodies: string[] = [];
const contacts: string[] = [];

beforeAll(async () => {
  t = await createTestDatabase();
  const app = testApp(t.db);
  const raw = inProcess(app);
  // Records every body this file sees (V-SEC-1).
  request = async (path, init) => {
    const res = await raw(path, init);
    bodies.push(await res.clone().text());
    return res;
  };
  host = await signIn(request, 'Amara Wanjiru');
  tunde = await signIn(request, 'Tunde Adeyemi');
});

afterAll(async () => {
  await t.drop();
});

async function setup(capacity = 5) {
  const a = await createActivity(request, host, { capacity });
  const booking = await bookOk(request, tunde, a.id);
  return { activityId: a.id, planId: booking.booking.planId };
}

const guest = (name = 'Zainab Okafor') => {
  const contact = newContact();
  contacts.push(contact);
  return { displayName: name, contact };
};

async function user(id: string) {
  const [row] = await t.admin<{ display_name: string; invite_generation: number }[]>`
    SELECT display_name, invite_generation FROM users WHERE id = ${id}`;
  return row!;
}

describe('claims', () => {
  // V-CLM-1 (FR-007, FR-008, FR-009, FR-011, FR-014)
  test('a new guest claims a vouch (web) and a public link (mobile)', async () => {
    const { activityId, planId } = await setup();
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    const res = await claim(request, vouch.code, guest());
    expect(res.status).toBe(201);
    expect(sessionCookie(res)).toBeTruthy();
    const body = ClaimResponse.parse(await res.json());
    expect(body.token).toBeUndefined();
    expect(body.booking).toMatchObject({ source: 'vouch', planId, activityId, status: 'confirmed' });
    expect(body.planId).toBe(planId);
    expect(body.user.displayName).toBe('Zainab Okafor');
    expect((await user(body.user.id)).invite_generation).toBe(1);
    const [claimRow] = await t.admin`SELECT rail FROM invite_claims WHERE booking_id = ${body.booking.id}`;
    expect(claimRow).toEqual({ rail: 'vouch' });
    const [attr] = await t.admin`
      SELECT inviter_id, invite_id, rail, generation, activity_id, chain_seq::int FROM attributions
       WHERE invitee_id = ${body.user.id}`;
    expect(attr).toEqual({
      inviter_id: tunde.id,
      invite_id: vouch.id,
      rail: 'vouch',
      generation: 1,
      activity_id: activityId,
      chain_seq: 1,
    });

    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const mobile = await claim(request, pub.code, guest('Kofi Mensah'), { mobile: true });
    expect(mobile.status).toBe(201);
    expect(sessionCookie(mobile)).toBeUndefined();
    const m = ClaimResponse.parse(await mobile.json());
    expect(m.token).toHaveLength(43);
    expect(m.booking.source).toBe('public');
    // The token works.
    const me = await request('/api/me', { headers: { authorization: `Bearer ${m.token!}` } });
    expect(((await me.json()) as { id: string }).id).toBe(m.user.id);
  });

  test('generation 2: a guest invites her own friend into the same Plan', async () => {
    const { planId } = await setup();
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });
    const z = ClaimResponse.parse(await (await claim(request, vouch.code, guest(), { mobile: true })).json());
    const zainab: Caller = { id: z.user.id, headers: { authorization: `Bearer ${z.token!}` } };
    const hers = await createInvite(request, zainab, planId, { rail: 'vouch', inviteeName: 'Ada' });
    const ada = ClaimResponse.parse(await (await claim(request, hers.code, guest('Ada Obi'))).json());
    expect(ada.planId).toBe(planId);
    expect((await user(ada.user.id)).invite_generation).toBe(2);
  });

  // V-CLM-2 (FR-008)
  test('existing users: by session, and by contact without a session', async () => {
    const { planId } = await setup();
    const signedIn = await signIn(request, 'Kofi Mensah');
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const a = await claim(request, pub.code, signedIn);
    expect(a.status).toBe(201);
    expect(sessionCookie(a)).toBeUndefined();
    expect(((await a.json()) as ClaimBody).user.id).toBe(signedIn.id);

    const contact = newContact();
    contacts.push(contact);
    const existing = await signIn(request, 'Ama Owusu', contact);
    const users = async () => (await t.admin<{ n: number }[]>`SELECT count(*)::int AS n FROM users`)[0]!.n;
    const before = await users();
    const b = await claim(request, pub.code, { displayName: 'Someone Else', contact });
    expect(b.status).toBe(201);
    expect(sessionCookie(b)).toBeTruthy();
    const body = (await b.json()) as ClaimBody;
    expect(body.user.id).toBe(existing.id);
    expect(body.user.displayName).toBe('Ama Owusu');
    expect(await users()).toBe(before);
    // Existing users keep generation 0 and get no attribution (PRD Identity, D4).
    expect((await user(existing.id)).invite_generation).toBe(0);
    expect(await t.admin`SELECT 1 FROM attributions WHERE invitee_id = ${existing.id}`).toHaveLength(0);
  });

  // V-CLM-3 (FR-009, FR-014)
  test('a retry without a session replays the claim and signs the guest in', async () => {
    const { activityId, planId } = await setup();
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const g = guest();
    const key = randomUUID();
    const first = (await (await claim(request, pub.code, g, { key })).json()) as ClaimBody;
    const again = await claim(request, pub.code, g, { key });
    expect(again.status).toBe(200);
    expect(sessionCookie(again)).toBeTruthy();
    expect(((await again.json()) as ClaimBody).booking.id).toBe(first.booking.id);
    const [row] = await t.admin<{ n: number }[]>`
      SELECT count(*)::int AS n FROM bookings WHERE activity_id = ${activityId}`;
    expect(row!.n).toBe(2);
  });

  // V-CLM-4 (FR-010)
  test('rejections, in order', async () => {
    const { activityId, planId } = await setup(2);
    const pub = await createInvite(request, tunde, planId, { rail: 'public' });
    const vouch = await createInvite(request, tunde, planId, { rail: 'vouch', inviteeName: 'Zainab' });

    const invalid = await claim(request, 'ZZZZZZ', guest());
    expect([invalid.status, await errorCode(invalid)]).toEqual([404, 'invalid_code']);
    const noIdentity = await request(`/api/invites/${pub.code}/claims`, {
      method: 'POST',
      headers: { 'idempotency-key': randomUUID(), 'x-device-id': randomUUID() },
    });
    expect(noIdentity.status).toBe(400);
    const noKey = await request(`/api/invites/${pub.code}/claims`, {
      method: 'POST',
      headers: tunde.headers,
    });
    expect(noKey.status).toBe(400);

    // Host on their own activity, then the inviter (already booked).
    const own = await claim(request, pub.code, host);
    expect([own.status, await errorCode(own)]).toEqual([403, 'forbidden']);
    const already = await claim(request, pub.code, tunde);
    expect([already.status, await errorCode(already)]).toEqual([409, 'already_booked']);

    // Vouch claimed by one guest: someone else gets already_claimed, the claimer gets their booking.
    const z = await signIn(request, 'Zainab Okafor');
    const zClaim = (await (await claim(request, vouch.code, z)).json()) as ClaimBody;
    const other = await claim(request, vouch.code, guest('Wrong Person'));
    expect([other.status, await errorCode(other)]).toEqual([409, 'already_claimed']);
    const mine = await claim(request, vouch.code, z);
    expect(mine.status).toBe(200);
    expect(((await mine.json()) as ClaimBody).booking.id).toBe(zClaim.booking.id);

    // Sold out: Tunde and Zainab hold both spots.
    const full = await claim(request, pub.code, guest('Late Comer'));
    expect([full.status, await errorCode(full)]).toEqual([409, 'sold_out']);

    // Removed by the host: can't claim back in.
    await removeBooking(request, host, zClaim.booking.id);
    const pub2 = await createInvite(request, tunde, planId, { rail: 'public' });
    const removed = await claim(request, pub2.code, z);
    expect([removed.status, await errorCode(removed)]).toEqual([409, 'booking_removed']);

    // Bookings paused, then started (expired wins over paused).
    await t.admin`UPDATE activities SET bookings_paused = true WHERE id = ${activityId}`;
    const paused = await claim(request, pub.code, guest('Paused Out'));
    expect([paused.status, await errorCode(paused)]).toEqual([409, 'bookings_paused']);
    await t.admin`ALTER TABLE activities DISABLE TRIGGER activities_location_lock`;
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 minute' WHERE id = ${activityId}`;
    await t.admin`ALTER TABLE activities ENABLE TRIGGER activities_location_lock`;
    const expired = await claim(request, pub.code, guest('Too Late'));
    expect([expired.status, await errorCode(expired)]).toEqual([410, 'invite_expired']);

    // No rejected claim created a user.
    const names = ['Wrong Person', 'Late Comer', 'Paused Out', 'Too Late'];
    expect(await t.admin`SELECT 1 FROM users WHERE display_name IN ${t.admin(names)}`).toHaveLength(0);
    const reasons = await t.admin<{ reason: string }[]>`
      SELECT props->>'reason' AS reason FROM events WHERE name = 'booking_rejected' AND activity_id = ${activityId}`;
    expect(new Set(reasons.map((r) => r.reason))).toEqual(
      new Set([
        'forbidden',
        'already_booked',
        'already_claimed',
        'sold_out',
        'booking_removed',
        'bookings_paused',
        'invite_expired',
      ]),
    );
  });

  // V-CLM-5 (FR-011, AC-002, D4)
  test('first claim wins: later claims and vouches never change attribution', async () => {
    const first = await setup();
    const pub = await createInvite(request, tunde, first.planId, { rail: 'public' });
    const kofi = ClaimResponse.parse(
      await (await claim(request, pub.code, guest('Kofi Mensah'), { mobile: true })).json(),
    );
    const kofiCaller: Caller = { id: kofi.user.id, headers: { authorization: `Bearer ${kofi.token!}` } };

    // Tunde later vouches for Kofi on another activity: a trust edge, attribution unchanged.
    const second = await setup();
    const vouch = await createInvite(request, tunde, second.planId, { rail: 'vouch', inviteeName: 'Kofi' });
    expect((await claim(request, vouch.code, kofiCaller)).status).toBe(201);
    const attrs =
      await t.admin`SELECT rail, generation, invite_id FROM attributions WHERE invitee_id = ${kofi.user.id}`;
    expect([...attrs]).toEqual([{ rail: 'public', generation: 1, invite_id: pub.id }]);
    const edges =
      await t.admin`SELECT voucher_id, invite_id FROM trust_edges WHERE vouchee_id = ${kofi.user.id}`;
    expect([...edges]).toEqual([{ voucher_id: tunde.id, invite_id: vouch.id }]);

    // An organic user claiming a vouch: trust edge, generation stays 0.
    const organic = await signIn(request, 'Organic User');
    const third = await setup();
    const v3 = await createInvite(request, tunde, third.planId, { rail: 'vouch', inviteeName: 'Organic' });
    expect((await claim(request, v3.code, organic)).status).toBe(201);
    expect((await user(organic.id)).invite_generation).toBe(0);
    expect(await t.admin`SELECT 1 FROM trust_edges WHERE vouchee_id = ${organic.id}`).toHaveLength(1);
  });

  // V-EVT-1 claims part (FR-013)
  test('invite_claimed and vouch_contact_mismatch events', async () => {
    const { planId } = await setup();
    const intended = newContact();
    const vouch = await createInvite(request, tunde, planId, {
      rail: 'vouch',
      inviteeName: 'Zainab',
      contact: intended,
    });
    const res = await claim(request, vouch.code, guest('Someone Else'));
    expect(res.status).toBe(201);
    const events = await t.admin<
      { name: string; props: Record<string, unknown>; rail: string; generation: number }[]
    >`
      SELECT name, props, rail, generation FROM events WHERE invite_id = ${vouch.id} ORDER BY id`;
    expect(events.map((e) => e.name)).toEqual([
      'invite_created',
      'invite_claimed',
      'vouch_contact_mismatch',
      'booking_succeeded',
    ]);
    expect(events[1]).toMatchObject({ props: { is_new_user: true }, rail: 'vouch', generation: 1 });

    // The intended person (matching contact) records no mismatch.
    const v2 = await createInvite(request, tunde, planId, {
      rail: 'vouch',
      inviteeName: 'Ada',
      contact: intended,
    });
    await claim(request, v2.code, { displayName: 'Ada Obi', contact: intended });
    expect(
      await t.admin`SELECT 1 FROM events WHERE invite_id = ${v2.id} AND name = 'vouch_contact_mismatch'`,
    ).toHaveLength(0);
  });
});

// V-SEC-1 (AC-008, SEC-002): no response in this file leaked a contact, a hash, or a note to the host.
test('no response contains a contact or a contact hash', async () => {
  expect(bodies.length).toBeGreaterThan(20);
  const hashes = (await t.admin<{ h: string }[]>`SELECT encode(contact_hash, 'hex') AS h FROM users`).map(
    (r) => r.h,
  );
  for (const body of bodies) {
    for (const c of contacts) expect(body).not.toContain(c);
    for (const h of hashes) expect(body).not.toContain(h);
    expect(body).not.toMatch(/contact_?hash/i);
  }
});
