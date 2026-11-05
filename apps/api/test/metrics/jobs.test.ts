// S8 jobs (V: T7): the oversell check and the attribution audit, called directly.
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createJobs, untilNextAudit } from '../../src/jobs/jobs';
import { createLogger } from '../../src/telemetry/logger';
import { insertActivity, insertBooking, insertInvite, insertPlan, insertUser } from '../helpers/fixtures';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;
let jobs: ReturnType<typeof createJobs>;

beforeAll(async () => {
  t = await createTestDatabase();
  jobs = createJobs({ db: t.db, logger: createLogger('silent') });
});

afterAll(async () => {
  await t.drop();
});

// FR-015, AC-007
describe('oversell check', () => {
  test('0 on a clean database; counts an activity with more confirmed bookings than capacity', async () => {
    expect(await jobs.checkOversell()).toBe(0);
    // Written as the superuser, past the booking engine: the state the check exists to catch.
    const host = await insertUser(t.admin, 'Amara Host');
    const a = await insertActivity(t.admin, host, { capacity: 1, spots_left: 0 });
    for (const name of ['One', 'Two']) {
      const u = await insertUser(t.admin, `Guest ${name}`);
      await insertBooking(t.admin, { activityId: a, userId: u, planId: await insertPlan(t.admin, a, u) });
    }
    expect(await jobs.checkOversell()).toBe(1);
  });
});

// FR-016, AC-007
describe('attribution audit', () => {
  test('no failures on intact chains; a hand edit is caught', async () => {
    const host = await insertUser(t.admin, 'Amara Host');
    const booker = await insertUser(t.admin, 'Tunde Booker');
    const a = await insertActivity(t.admin, host);
    const plan = await insertPlan(t.admin, a, booker);
    await insertBooking(t.admin, { activityId: a, userId: booker, planId: plan });
    const invite = await insertInvite(t.admin, { activityId: a, planId: plan, inviterId: booker });
    expect((await jobs.audit()).failures).toEqual([]);

    await t.admin`ALTER TABLE invites DISABLE TRIGGER invites_insert_only`;
    await t.admin`UPDATE invites SET invitee_name = 'Someone Else' WHERE id = ${invite}`;
    await t.admin`ALTER TABLE invites ENABLE TRIGGER invites_insert_only`;
    const result = await jobs.audit();
    expect(result.failures).toEqual([{ activityId: a, table: 'invites', firstBadSeq: expect.any(Number) }]);
    expect(jobs.lastAudit()).toBe(result);
  });

  test('the next run is at 02:00 UTC', () => {
    expect(untilNextAudit(new Date('2026-11-05T01:00:00Z'))).toBe(3_600_000);
    expect(untilNextAudit(new Date('2026-11-05T02:00:00Z'))).toBe(86_400_000);
    expect(untilNextAudit(new Date('2026-11-05T23:00:00Z'))).toBe(3 * 3_600_000);
  });
});
