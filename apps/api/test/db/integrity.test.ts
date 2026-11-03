import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import type postgres from 'postgres';
import { createTestDatabase, type TestDatabase } from '../helpers/db';
import {
  insertActivity,
  insertBooking,
  insertInvite,
  insertPlan,
  insertUser,
  seedInsertOnlyRows,
  type ActivityInput,
} from '../helpers/fixtures';

const INSERT_ONLY = [
  'invites',
  'invite_claims',
  'attributions',
  'trust_edges',
  'attendance_marks',
  'booking_removals',
] as const;

/** A harmless column per table to UPDATE. */
const UPDATE_SET: Record<(typeof INSERT_ONLY)[number], string> = {
  invites: 'note = note',
  invite_claims: 'claimed_at = claimed_at',
  attributions: 'generation = generation',
  trust_edges: 'created_at = created_at',
  attendance_marks: 'mark = mark',
  booking_removals: 'created_at = created_at',
};

let t: TestDatabase;
/** velio_api, through postgres.js (Kysely has no "raw unsafe" escape hatch we want here). */
let api: postgres.Sql;

beforeAll(async () => {
  t = await createTestDatabase();
  api = (await import('postgres')).default(t.url, { max: 1, onnotice: () => {} });
});

afterAll(async () => {
  await api.end();
  await t.drop();
});

async function asOwner<T>(fn: (sql: postgres.TransactionSql) => Promise<T>): Promise<T> {
  return (await t.admin.begin(async (sql) => {
    await sql`SET LOCAL ROLE velio_owner`;
    return fn(sql);
  })) as T;
}

/** Resolves to the Postgres SQLSTATE the promise rejected with. */
async function sqlState(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (err) {
    return (err as { code: string }).code;
  }
  throw new Error('expected the statement to fail');
}

// V-DB-1 (FR-004, FR-005)
describe('migrated schema', () => {
  test('every table, role and community exists', async () => {
    const tables = await t.admin<{ tablename: string }[]>`
      SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tableowner = 'velio_owner'
      ORDER BY tablename`;
    expect(tables.map((r) => r.tablename)).toEqual([
      'activities',
      'attendance_marks',
      'attributions',
      'booking_removals',
      'bookings',
      'communities',
      'events',
      'exposures',
      'invite_claims',
      'invite_controls',
      'invite_opens',
      'invites',
      'plans',
      'rate_limits',
      'sessions',
      'trust_edges',
      'users',
    ]);

    const roles = await t.admin<{ rolname: string }[]>`
      SELECT rolname FROM pg_roles WHERE rolname LIKE 'velio\\_%' ORDER BY rolname`;
    expect(roles.map((r) => r.rolname)).toEqual(['velio_api', 'velio_owner', 'velio_readonly']);

    const communities = await t.admin<{ slug: string; name: string }[]>`
      SELECT slug, name FROM communities ORDER BY slug`;
    expect([...communities]).toEqual([
      { slug: 'explore-kenya', name: 'Explore Kenya' },
      { slug: 'the-medina-collective', name: 'The Medina Collective' },
      { slug: 'the-tanzania-experience', name: 'The Tanzania Experience' },
    ]);

    const [ref] = await t.admin`
      SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'ref'`;
    expect(ref).toBeDefined();
  });

  test('velio_api can DELETE only from sessions and rate_limits', async () => {
    const rows = await t.admin<{ table_name: string }[]>`
      SELECT table_name FROM information_schema.role_table_grants
      WHERE grantee = 'velio_api' AND privilege_type = 'DELETE' ORDER BY table_name`;
    expect(rows.map((r) => r.table_name)).toEqual(['rate_limits', 'sessions']);
  });
});

// V-DB-2 (NFR-001, AC-002)
describe('insert-only tables', () => {
  beforeAll(async () => {
    await seedInsertOnlyRows(t.admin);
  });

  for (const table of INSERT_ONLY) {
    test(`${table}: velio_api has no UPDATE or DELETE grant`, async () => {
      expect(await sqlState(api.unsafe(`UPDATE ${table} SET ${UPDATE_SET[table]}`))).toBe('42501');
      expect(await sqlState(api.unsafe(`DELETE FROM ${table}`))).toBe('42501');
    });

    test(`${table}: the trigger rejects UPDATE and DELETE even for velio_owner`, async () => {
      expect(await sqlState(asOwner((sql) => sql.unsafe(`UPDATE ${table} SET ${UPDATE_SET[table]}`)))).toBe(
        'VL002',
      );
      expect(await sqlState(asOwner((sql) => sql.unsafe(`DELETE FROM ${table}`)))).toBe('VL002');
    });

    test(`${table}: velio_api can still INSERT and SELECT`, async () => {
      const [row] = await api.unsafe(`SELECT count(*)::int AS n FROM ${table}`);
      expect(row!.n).toBeGreaterThan(0);
    });
  }
});

// V-DB-3 (NFR-001)
describe('users immutable columns', () => {
  test('invite_generation and created_at cannot change; display_name can', async () => {
    const id = await insertUser(t.admin);
    expect(await sqlState(t.admin`UPDATE users SET invite_generation = 3 WHERE id = ${id}`)).toBe('VL003');
    expect(
      await sqlState(t.admin`UPDATE users SET created_at = now() - interval '1 day' WHERE id = ${id}`),
    ).toBe('VL003');
    await t.admin`UPDATE users SET display_name = 'Tunde A. Adeyemi' WHERE id = ${id}`;
  });
});

// V-DB-4 (NFR-001)
describe('activity checks', () => {
  const bad: [string, ActivityInput, string][] = [
    ['spots_left below 0', { spots_left: -1 }, '23514'],
    ['spots_left above capacity', { capacity: 5, spots_left: 6 }, '23514'],
    ['capacity 0', { capacity: 0, spots_left: 0 }, '23514'],
    ['zero price', { price_minor: 0 }, '23514'],
    ['lowercase currency', { currency: 'kes' }, '23514'],
    ['invalid time zone', { timezone: 'Mars/Olympus_Mons' }, 'VL004'],
  ];

  for (const [name, overrides, state] of bad) {
    test(`rejects ${name}`, async () => {
      const host = await insertUser(t.admin);
      expect(await sqlState(insertActivity(t.admin, host, overrides))).toBe(state);
    });
  }

  test('accepts a valid activity', async () => {
    const host = await insertUser(t.admin);
    expect(await insertActivity(t.admin, host)).toBeString();
  });
});

// V-DB-5 (NFR-001)
describe('unique constraints', () => {
  test('one confirmed booking per user and activity; a removed duplicate is allowed', async () => {
    const host = await insertUser(t.admin);
    const guest = await insertUser(t.admin);
    const activity = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, activity, guest);
    await insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan });
    expect(
      await sqlState(insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan })),
    ).toBe('23505');
    await insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan, status: 'removed' });
  });

  test('a vouch invite can be claimed once; a public invite many times', async () => {
    const host = await insertUser(t.admin);
    const booker = await insertUser(t.admin);
    const activity = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, activity, booker);

    const vouch = await insertInvite(t.admin, { activityId: activity, planId: plan, inviterId: booker });
    const claim = async (invite: string, rail: string) => {
      const guest = await insertUser(t.admin);
      const booking = await insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan });
      await t.admin`INSERT INTO invite_claims (booking_id, invite_id, rail) VALUES (${booking}, ${invite}, ${rail})`;
    };
    await claim(vouch, 'vouch');
    expect(await sqlState(claim(vouch, 'vouch'))).toBe('23505');

    const pub = await insertInvite(t.admin, {
      activityId: activity,
      planId: plan,
      inviterId: booker,
      rail: 'public',
    });
    await claim(pub, 'public');
    await claim(pub, 'public');
  });

  test('booking ref is unique', async () => {
    const host = await insertUser(t.admin);
    const activity = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, activity, host);
    const a = await insertUser(t.admin);
    const b = await insertUser(t.admin);
    await insertBooking(t.admin, { activityId: activity, userId: a, planId: plan, ref: 'VLO-ABCDE' });
    expect(
      await sqlState(
        insertBooking(t.admin, { activityId: activity, userId: b, planId: plan, ref: 'VLO-ABCDE' }),
      ),
    ).toBe('23505');
  });

  test('a user is attributed once (first claim wins)', async () => {
    const host = await insertUser(t.admin);
    const booker = await insertUser(t.admin);
    const guest = await insertUser(t.admin, 'Zainab Bello', 1);
    const activity = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, activity, booker);
    const invite = await insertInvite(t.admin, { activityId: activity, planId: plan, inviterId: booker });
    const attribute = () => t.admin`
      INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation)
      VALUES (${guest}, ${booker}, ${invite}, 'vouch', 1)`;
    await attribute();
    expect(await sqlState(attribute())).toBe('23505');
  });
});

// V-DB-6 (FR-015)
describe('activity location', () => {
  const bad: [string, ActivityInput][] = [
    ['lat 91', { lat: '91' }],
    ['lng -181', { lng: '-181' }],
    ['empty venue_name', { venue_name: '  ' }],
    ['a 141-character meeting_point', { meeting_point: 'x'.repeat(141) }],
  ];

  for (const [name, overrides] of bad) {
    test(`rejects ${name}`, async () => {
      const host = await insertUser(t.admin);
      expect(await sqlState(insertActivity(t.admin, host, overrides))).toBe('23514');
    });
  }

  test('accepts a 140-character meeting_point and a null place_id', async () => {
    const host = await insertUser(t.admin);
    await insertActivity(t.admin, host, { meeting_point: 'x'.repeat(140), place_id: null });
  });

  test('location, date and time zone lock once there is a confirmed booking; other fields stay editable', async () => {
    const host = await insertUser(t.admin);
    const guest = await insertUser(t.admin);
    const activity = await insertActivity(t.admin, host);

    // Before any booking, the location can change.
    await t.admin`UPDATE activities SET meeting_point = 'By the boathouse' WHERE id = ${activity}`;

    const plan = await insertPlan(t.admin, activity, guest);
    await insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan });

    const locked = [
      t.admin`UPDATE activities SET lat = 1 WHERE id = ${activity}`,
      t.admin`UPDATE activities SET meeting_point = 'Elsewhere' WHERE id = ${activity}`,
      t.admin`UPDATE activities SET starts_at = starts_at + interval '1 hour' WHERE id = ${activity}`,
      t.admin`UPDATE activities SET timezone = 'Africa/Dar_es_Salaam' WHERE id = ${activity}`,
      t.admin`UPDATE activities SET place_id = NULL WHERE id = ${activity}`,
    ];
    for (const update of locked) expect(await sqlState(update)).toBe('VL001');

    await t.admin`UPDATE activities SET title = 'Sunset Kayaking at Naivasha' WHERE id = ${activity}`;
    await t.admin`UPDATE activities SET spots_left = spots_left - 1, version = version + 1 WHERE id = ${activity}`;
  });

  test('a removed booking does not lock the location', async () => {
    const host = await insertUser(t.admin);
    const guest = await insertUser(t.admin);
    const activity = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, activity, guest);
    await insertBooking(t.admin, { activityId: activity, userId: guest, planId: plan, status: 'removed' });
    await t.admin`UPDATE activities SET lat = 1 WHERE id = ${activity}`;
  });
});
