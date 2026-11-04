import type { ActivityState } from '@velio/contracts';
import { sql, type Transaction } from 'kysely';
import type { DB } from '../../db/types';

// Postgres delivers a notification only when its transaction commits, in commit order (MVP plan
// §4.2). Each helper is the last statement of the transaction that changed something.

export const CHANNELS = {
  spots: 'activity_spots',
  plan: 'plan_changed',
  attendance: 'attendance_changed',
} as const;

type Tx = Transaction<DB>;

/** Every committed change to spots_left. `committedAt` is the latency reference (S3 §4.8). */
export async function notifySpots(tx: Tx, state: ActivityState) {
  await sql`
    SELECT pg_notify(${CHANNELS.spots}, json_build_object(
      'activityId', ${state.id}::uuid,
      'spotsLeft', ${state.spotsLeft}::int,
      'version', ${state.version}::bigint,
      'committedAt', clock_timestamp())::text)`.execute(tx);
}

/** Something in a Plan changed (member joined or removed; S4: invites). Clients refetch the Plan. */
export async function notifyPlan(tx: Tx, planId: string) {
  await sql`
    SELECT pg_notify(${CHANNELS.plan}, json_build_object('planId', ${planId}::uuid)::text)`.execute(tx);
}

/** An attendance change that doesn't move spots (S4: attendance marks). The host refetches. */
export async function notifyAttendance(tx: Tx, activityId: string) {
  await sql`
    SELECT pg_notify(${CHANNELS.attendance}, json_build_object('activityId', ${activityId}::uuid)::text)`.execute(
    tx,
  );
}
