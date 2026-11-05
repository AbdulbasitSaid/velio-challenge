// S8 holdout (V: T1, T2): stable arms, exposure logged once, invite tools withheld by the server.
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { randomUUID } from 'node:crypto';
import { PlanView } from '@velio/contracts';
import { armOf } from '../../src/modules/flags/holdout';
import { testApp } from '../helpers/app';
import {
  bookOk,
  createActivity,
  errorCode,
  inProcess,
  postInvite,
  signIn,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;

beforeAll(async () => {
  t = await createTestDatabase();
});

afterAll(async () => {
  await t.drop();
});

// FR-001, AC-001
describe('armOf', () => {
  test('about 10% holdout over 10,000 IDs, and the same arm every time', () => {
    const ids = Array.from({ length: 10_000 }, () => randomUUID());
    const holdout = ids.filter((id) => armOf(id, 10) === 'holdout').length;
    expect(holdout).toBeGreaterThanOrEqual(900);
    expect(holdout).toBeLessThanOrEqual(1100);
    for (const id of ids.slice(0, 100)) expect(armOf(id, 10)).toBe(armOf(id, 10));
  });

  test('0% and 100% are absolute', () => {
    const id = randomUUID();
    expect(armOf(id, 0)).toBe('exposed');
    expect(armOf(id, 100)).toBe('holdout');
  });
});

// FR-002, FR-003, AC-002
describe('holdout on the API', () => {
  async function bookerWithPlan(request: Requester) {
    const host = await signIn(request, 'Amara Host');
    const booker = await signIn(request, 'Tunde Booker');
    const a = await createActivity(request, host);
    const { booking } = await bookOk(request, booker, a.id);
    const viewPlan = async () =>
      PlanView.parse(
        await (await request(`/api/plans/${booking.planId}`, { headers: booker.headers })).json(),
      );
    return { booker, planId: booking.planId, viewPlan };
  }
  const exposures = (userId: string) =>
    t.admin<
      { arm: string }[]
    >`SELECT arm FROM exposures WHERE user_id = ${userId} AND flag = 'group_invites'`;

  test('holdout: no invite tools, invite create refused, one exposure row', async () => {
    const request = inProcess(testApp(t.db, undefined, { HOLDOUT_PERCENT: '100' }));
    const { booker, planId, viewPlan } = await bookerWithPlan(request);
    expect((await viewPlan()).viewer.canInvite).toBe(false);
    await viewPlan();
    const res = await postInvite(request, booker, planId, { rail: 'public' });
    expect(res.status).toBe(403);
    expect(await errorCode(res)).toBe('invites_unavailable');
    expect([...(await exposures(booker.id))]).toEqual([{ arm: 'holdout' }]);
  });

  test('exposed: invite tools and an exposed row', async () => {
    const request = inProcess(testApp(t.db, undefined, { HOLDOUT_PERCENT: '0' }));
    const { booker, planId, viewPlan } = await bookerWithPlan(request);
    expect((await viewPlan()).viewer.canInvite).toBe(true);
    expect((await postInvite(request, booker, planId, { rail: 'public' })).status).toBe(201);
    expect([...(await exposures(booker.id))]).toEqual([{ arm: 'exposed' }]);
  });
});
