import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { Kysely } from 'kysely';
import { PostgresJSDialect } from 'kysely-postgres-js';
import postgres from 'postgres';
import { PublicActivity } from '@velio/contracts';
import type { DB } from '../../src/db/types';
import { buildSnapshot, directionsUrl, summarise } from '../../src/modules/activities/snapshot';
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

async function snapshot(id: string, caller?: Caller) {
  const res = await request(`/api/activities/${id}`, { headers: caller?.headers ?? {} });
  return { res, body: res.status === 200 ? PublicActivity.parse(await res.json()) : undefined };
}

describe('GET /api/activities/:id', () => {
  // S6 V-MAP-1: with Static Maps configured, the snapshot carries a signed image URL.
  test('staticMapUrl is signed when the key and secret are configured', async () => {
    const signed = inProcess(
      testApp(t.db, undefined, {
        GOOGLE_MAPS_SERVER_KEY: 'test-key',
        GOOGLE_MAPS_SIGNING_SECRET: 'vNIXE0xscrmjlyV-12Nj_BvUPaw=',
      }),
    );
    const a = await createActivity(request, host, { capacity: 3 });
    const body = PublicActivity.parse(await (await signed(`/api/activities/${a.id}`)).json());
    const url = new URL(body.location.staticMapUrl!);
    expect(url.pathname).toBe('/maps/api/staticmap');
    expect(url.searchParams.get('center')).toBe('-0.7667,36.4333');
    expect(url.searchParams.get('key')).toBe('test-key');
    expect(url.searchParams.get('signature')).toMatch(/^[A-Za-z0-9_-]{27}=$/);
  });

  // V-SNAP-1 (FR-001, FR-004, SEC-001)
  test('anonymous: public shape, short names, no viewer, no-store', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    await book(request, tunde, a.id);
    const { res, body } = await snapshot(a.id);
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    expect(body!.viewer).toBeNull();
    expect(body!.host).toEqual({ id: host.id, shortName: 'Amara W.', avatarSeed: host.id });
    expect(body!.members).toEqual({
      count: 1,
      preview: [{ id: tunde.id, shortName: 'Tunde A.', avatarSeed: tunde.id }],
    });
    expect(body!.spotsLeft).toBe(2);
    expect(body!.version).toBe(1);
    expect(body!.community).toEqual({ slug: 'explore-kenya', name: expect.any(String) });
    expect(body!.location.staticMapUrl).toBeNull();
    expect(body!.location.directionsUrl).toBe(
      'https://www.google.com/maps/dir/?api=1&destination=-0.7667%2C36.4333&destination_place_id=ChIJ_example',
    );
    // No full names anywhere in a public response.
    const text = JSON.stringify(await (await request(`/api/activities/${a.id}`)).json());
    expect(text).not.toContain('Adeyemi');
    expect(text).not.toContain('Wanjiru');
    expect(text).not.toContain('example.com');
  });

  test('signed in: the viewer field for a member, the host, a removed member and an outsider', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    const booked = (await (await book(request, tunde, a.id)).json()) as BookingBody;
    const asTunde = (await snapshot(a.id, tunde)).body!;
    expect(asTunde.viewer).toEqual({
      isHost: false,
      booking: { id: booked.booking.id, planId: booked.booking.planId, status: 'confirmed' },
    });
    expect((await snapshot(a.id, host)).body!.viewer).toEqual({ isHost: true, booking: null });
    expect((await snapshot(a.id, zainab)).body!.viewer).toEqual({ isHost: false, booking: null });

    await removeBooking(request, host, booked.booking.id);
    const removed = (await snapshot(a.id, tunde)).body!;
    expect(removed.viewer!.booking!.status).toBe('removed');
    expect(removed.members.count).toBe(0);
  });

  test('members: count is the total, preview the earliest 8', async () => {
    const a = await createActivity(request, host, { capacity: 12 });
    const guests: Caller[] = [];
    for (let i = 0; i < 10; i++) {
      const g = await signIn(request, `Guest Number${i}`);
      guests.push(g);
      await book(request, g, a.id);
    }
    const body = (await snapshot(a.id)).body!;
    expect(body.members.count).toBe(10);
    expect(body.members.preview.map((p) => p.id)).toEqual(guests.slice(0, 8).map((g) => g.id));
  });

  // V-SNAP-2
  test('unknown and malformed IDs', async () => {
    const unknown = await request(`/api/activities/${UNKNOWN_ID}`);
    expect(unknown.status).toBe(404);
    expect(await errorCode(unknown)).toBe('not_found');
    const malformed = await request('/api/activities/not-a-uuid');
    expect(malformed.status).toBe(400);
    expect(await errorCode(malformed)).toBe('validation_failed');
  });

  // V-SNAP-4 (FR-003, AC-006)
  test('status: open, sold out, started, and started wins over sold out', async () => {
    const open = await createActivity(request, host, { capacity: 1 });
    expect((await snapshot(open.id)).body!.status).toBe('open');
    await book(request, tunde, open.id);
    expect((await snapshot(open.id)).body!.status).toBe('sold_out');

    const started = await createActivity(request, host, { capacity: 2 });
    await t.admin`UPDATE activities SET starts_at = now() - interval '1 hour' WHERE id = ${started.id}`;
    expect((await snapshot(started.id)).body!.status).toBe('started');
    await t.admin`UPDATE activities SET spots_left = 0, capacity = 2 WHERE id = ${started.id}`;
    expect((await snapshot(started.id)).body!.status).toBe('started');
  });
});

// V-SNAP-3 (FR-002, NFR-006)
describe('buildSnapshot query count', () => {
  test('two queries anonymous, three signed in; spots and version from one statement', async () => {
    const a = await createActivity(request, host, { capacity: 3 });
    await book(request, tunde, a.id);
    const queries: string[] = [];
    const sql = postgres(t.url, { max: 1, onnotice: () => {} });
    const counted = new Kysely<DB>({
      dialect: new PostgresJSDialect({ postgres: sql }),
      log: (e) => {
        queries.push(e.query.sql);
      },
    });
    try {
      await buildSnapshot(counted, a.id, null);
      expect(queries).toHaveLength(2);
      expect(queries[0]).toContain('"spots_left"');
      expect(queries[0]).toContain('"version"');
      queries.length = 0;
      await buildSnapshot(counted, a.id, tunde.id);
      expect(queries).toHaveLength(3);
    } finally {
      await counted.destroy();
    }
  });
});

test('directionsUrl without a place ID', () => {
  expect(directionsUrl(1.5, -2.25, null)).toBe(
    'https://www.google.com/maps/dir/?api=1&destination=1.5%2C-2.25',
  );
});

// Explore map preview FR-001, AC-002
describe('summarise', () => {
  test('empty and short descriptions pass through, whitespace collapsed', () => {
    expect(summarise('')).toBe('');
    expect(summarise('   ')).toBe('');
    expect(summarise('  Two hours\n\non the   lake. ')).toBe('Two hours on the lake.');
  });

  test('long text is cut at a word within 140 characters, trailing punctuation dropped', () => {
    const text = `${'abcd '.repeat(27)}tail, ${'more '.repeat(20)}`;
    const out = summarise(text);
    expect(out).toBe(`${'abcd '.repeat(27)}tail…`);
    expect(out.length).toBeLessThanOrEqual(141);
  });

  test('a single long word is hard-cut at 140', () => {
    expect(summarise('x'.repeat(300))).toBe(`${'x'.repeat(140)}…`);
  });

  test('text already cut by the query ends with an ellipsis', () => {
    expect(summarise('Short head.', true)).toBe('Short head…');
  });
});
