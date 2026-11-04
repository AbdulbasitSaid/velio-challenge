import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createHash, randomBytes } from 'node:crypto';
import postgres from 'postgres';
import { createTestDatabase, type TestDatabase } from '../helpers/db';
import {
  insertActivity,
  insertBooking,
  insertInvite,
  insertPlan,
  insertUser,
  inviteCode,
} from '../helpers/fixtures';

// S4 V-DB-2…4: the per-activity hash chain, the audit function and insert-only rules.

let t: TestDatabase;
/** velio_api, the runtime role. */
let api: postgres.Sql;

beforeAll(async () => {
  t = await createTestDatabase();
  api = postgres(t.url, { max: 1, onnotice: () => {} });
});

afterAll(async () => {
  await api.end();
  await t.drop();
});

async function world() {
  const host = await insertUser(t.admin, 'Amara Wanjiru');
  const booker = await insertUser(t.admin, 'Tunde Adeyemi');
  const activity = await insertActivity(t.admin, host);
  const plan = await insertPlan(t.admin, activity, booker);
  return { host, booker, activity, plan };
}

type Row = { id: string; chain_seq: string; prev_hash: Buffer; row_hash: Buffer };

async function chain(table: 'invites' | 'attributions', activity: string) {
  return t.admin<Row[]>`
    SELECT ${t.admin(table === 'invites' ? 'id' : 'invitee_id')} AS id, chain_seq, prev_hash, row_hash
      FROM ${t.admin(table)} WHERE activity_id = ${activity} ORDER BY chain_seq`;
}

const audit = (activity: string) =>
  t.admin<{ table_name: string; first_bad_seq: string }[]>`SELECT * FROM audit_chain(${activity})`;

/** Disables a table's insert-only trigger as the owner (test only), runs `fn`, and re-enables it. */
async function tamper(table: string, fn: () => Promise<unknown>) {
  await t.admin.unsafe(`ALTER TABLE ${table} DISABLE TRIGGER ${table}_insert_only`);
  try {
    await fn();
  } finally {
    await t.admin.unsafe(`ALTER TABLE ${table} ENABLE TRIGGER ${table}_insert_only`);
  }
}

describe('hash chain', () => {
  // V-DB-2 (FR-015, SEC-005)
  test('the trigger assigns chain_seq and hashes, per activity, overwriting caller values', async () => {
    const a = await world();
    const b = await world();
    for (let i = 0; i < 3; i++) {
      await api`
        INSERT INTO invites (code, rail, activity_id, plan_id, inviter_id, invitee_name, chain_seq, prev_hash, row_hash)
        VALUES (${inviteCode()}, 'vouch', ${a.activity}, ${a.plan}, ${a.booker}, 'Friend', 999, ${randomBytes(32)}, ${randomBytes(32)})`;
    }
    await insertInvite(t.admin, { activityId: b.activity, planId: b.plan, inviterId: b.booker });

    const rows = await chain('invites', a.activity);
    expect(rows.map((r) => Number(r.chain_seq))).toEqual([1, 2, 3]);
    expect(rows[0]!.prev_hash.equals(Buffer.alloc(32))).toBe(true);
    for (let i = 1; i < rows.length; i++) expect(rows[i]!.prev_hash.equals(rows[i - 1]!.row_hash)).toBe(true);
    // Each row_hash recomputes from prev_hash and the canonical row.
    for (const r of rows) {
      const [c] = await t.admin<
        { text: string }[]
      >`SELECT invite_canonical(i) AS text FROM invites i WHERE id = ${r.id}`;
      const expected = createHash('sha256')
        .update(Buffer.concat([r.prev_hash, Buffer.from(c!.text, 'utf8')]))
        .digest();
      expect(r.row_hash.equals(expected)).toBe(true);
    }
    expect((await chain('invites', b.activity)).map((r) => Number(r.chain_seq))).toEqual([1]);
    expect(await audit(a.activity)).toHaveLength(0);
  });

  test('attributions take their activity from the invite and chain separately', async () => {
    const w = await world();
    const invite = await insertInvite(t.admin, {
      activityId: w.activity,
      planId: w.plan,
      inviterId: w.booker,
    });
    const other = await world();
    for (let i = 0; i < 2; i++) {
      const guest = await insertUser(t.admin, `Guest ${i}`, 1);
      await insertBooking(t.admin, {
        activityId: w.activity,
        userId: guest,
        planId: w.plan,
        source: 'vouch',
        inviteId: invite,
      });
      // A wrong activity_id from the caller is replaced by the invite's.
      await api`
        INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation, activity_id)
        VALUES (${guest}, ${w.booker}, ${invite}, 'vouch', 1, ${other.activity})`;
    }
    const rows = await chain('attributions', w.activity);
    expect(rows.map((r) => Number(r.chain_seq))).toEqual([1, 2]);
    expect(await chain('attributions', other.activity)).toHaveLength(0);
    expect(await audit(w.activity)).toHaveLength(0);
  });

  // V-DB-3 (FR-016, AC-004)
  test('the audit reports a tampered row, a deleted row, and nothing for a clean chain', async () => {
    const w = await world();
    const invite = await insertInvite(t.admin, {
      activityId: w.activity,
      planId: w.plan,
      inviterId: w.booker,
    });
    const guests: string[] = [];
    for (let i = 0; i < 3; i++) {
      const g = await insertUser(t.admin, `Chain ${i}`, 1);
      guests.push(g);
      await t.admin`
        INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation)
        VALUES (${g}, ${w.booker}, ${invite}, 'vouch', 1)`;
    }
    expect(await audit(w.activity)).toHaveLength(0);

    await tamper(
      'attributions',
      () => t.admin`UPDATE attributions SET generation = 5 WHERE invitee_id = ${guests[1]!}`,
    );
    expect([...(await audit(w.activity))]).toEqual([{ table_name: 'attributions', first_bad_seq: '2' }]);

    const w2 = await world();
    const inv2 = await insertInvite(t.admin, {
      activityId: w2.activity,
      planId: w2.plan,
      inviterId: w2.booker,
    });
    for (let i = 0; i < 3; i++) {
      const g = await insertUser(t.admin, `Gap ${i}`, 1);
      await t.admin`
        INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation)
        VALUES (${g}, ${w2.booker}, ${inv2}, 'public', 1)`;
    }
    await tamper(
      'attributions',
      () => t.admin`DELETE FROM attributions WHERE activity_id = ${w2.activity} AND chain_seq = 2`,
    );
    expect([...(await audit(w2.activity))]).toEqual([{ table_name: 'attributions', first_bad_seq: '3' }]);

    // An edited invite (the note) is caught in the invites chain.
    await tamper('invites', () => t.admin`UPDATE invites SET note = 'edited' WHERE id = ${inv2}`);
    const both = await audit(w2.activity);
    expect(both).toContainEqual({ table_name: 'invites', first_bad_seq: '1' });

    const all = await t.admin<{ activity_id: string }[]>`SELECT activity_id FROM audit_all_chains()`;
    expect(new Set(all.map((r) => r.activity_id))).toEqual(new Set([w.activity, w2.activity]));
  });
});

// V-DB-4 (AC-005, SEC-001)
describe('insert-only for the API role', () => {
  test('UPDATE and DELETE fail on invites, invite_claims, attributions and trust_edges', async () => {
    const w = await world();
    const invite = await insertInvite(t.admin, {
      activityId: w.activity,
      planId: w.plan,
      inviterId: w.booker,
    });
    const guest = await insertUser(t.admin, 'Insert Only', 1);
    const booking = await insertBooking(t.admin, {
      activityId: w.activity,
      userId: guest,
      planId: w.plan,
      source: 'vouch',
      inviteId: invite,
    });
    await t.admin`INSERT INTO invite_claims (booking_id, invite_id, rail) VALUES (${booking}, ${invite}, 'vouch')`;
    await t.admin`INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation) VALUES (${guest}, ${w.booker}, ${invite}, 'vouch', 1)`;
    await t.admin`INSERT INTO trust_edges (voucher_id, vouchee_id, invite_id) VALUES (${w.booker}, ${guest}, ${invite})`;
    const timestamps = {
      invites: 'created_at',
      invite_claims: 'claimed_at',
      attributions: 'created_at',
      trust_edges: 'created_at',
    };
    for (const [table, column] of Object.entries(timestamps)) {
      await expect(api.unsafe(`UPDATE ${table} SET ${column} = ${column}`)).rejects.toThrow(
        /permission denied/,
      );
      await expect(api.unsafe(`DELETE FROM ${table}`)).rejects.toThrow(/permission denied/);
    }
  });
});
