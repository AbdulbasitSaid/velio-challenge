import { Topic } from '@velio/contracts';
import type { Db } from '../../db/client';

export type TopicKind = 'activity' | 'plan' | 'host';

export interface ParsedTopic {
  topic: string;
  kind: TopicKind;
  id: string;
}

export function parseTopic(raw: string): ParsedTopic | undefined {
  if (!Topic.safeParse(raw).success) return undefined;
  const [kind, id] = raw.split(':') as [TopicKind, string];
  return { topic: raw, kind, id };
}

export const activityTopic = (id: string) => `activity:${id}`;
export const planTopic = (id: string) => `plan:${id}`;
export const hostTopic = (activityId: string) => `host:${activityId}`;

/**
 * Who may subscribe (S3 FR-007), checked against the database at subscribe time: activity topics
 * are public; Plan topics need a booking of any status in the Plan (a removed member still sees
 * the removal live); host topics need the activity's host.
 */
export async function authorizeTopic(
  db: Db,
  topic: ParsedTopic,
  userId: string | null,
): Promise<'ok' | 'forbidden' | 'not_found'> {
  if (topic.kind === 'activity') {
    const row = await db.selectFrom('activities').select('id').where('id', '=', topic.id).executeTakeFirst();
    return row ? 'ok' : 'not_found';
  }
  if (topic.kind === 'host') {
    const row = await db
      .selectFrom('activities')
      .select('host_id')
      .where('id', '=', topic.id)
      .executeTakeFirst();
    if (!row) return 'not_found';
    return userId !== null && row.host_id === userId ? 'ok' : 'forbidden';
  }
  const plan = await db.selectFrom('plans').select('id').where('id', '=', topic.id).executeTakeFirst();
  if (!plan) return 'not_found';
  if (userId === null) return 'forbidden';
  const member = await db
    .selectFrom('bookings')
    .select('id')
    .where('plan_id', '=', topic.id)
    .where('user_id', '=', userId)
    .executeTakeFirst();
  return member ? 'ok' : 'forbidden';
}
