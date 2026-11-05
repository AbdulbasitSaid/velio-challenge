import { createHash } from 'node:crypto';
import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { ClientEvent, DeviceId } from '@velio/contracts';
import { sql } from 'kysely';
import type { AppEnv } from '../../app';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { errorResponse, SECURITY } from '../../openapi';
import type { Limits } from '../invites/limits';
import { clientIp } from '../invites/routes';
import type { EventMetrics } from './metrics';

/** Engineering limit, not a PRD figure (S8 PLANNING §4.2): a page sends about six events. */
export const EVENTS_PER_MINUTE = 60;

const sha = (value: string) => createHash('sha256').update(value).digest('hex');

const eventRoute = createRoute({
  method: 'post',
  path: '/events',
  summary: 'Client analytics: activity views and Web Vitals',
  description:
    'Only `activity_viewed` (stored as a funnel event) and `web_vital` (a metric sample, never stored) are accepted. At most 60 per device per minute.',
  security: [...SECURITY, {}],
  request: {
    headers: z.object({
      'x-device-id': DeviceId.optional(),
      'x-client': z.enum(['web', 'mobile']).optional(),
    }),
    body: { required: true, content: { 'application/json': { schema: ClientEvent } } },
  },
  responses: {
    204: { description: 'Received' },
    400: errorResponse('`validation_failed`: unknown name or bad payload'),
    429: errorResponse('`rate_limited`'),
  },
});

export function eventRoutes(deps: { db: Db; limits: Limits; metrics: EventMetrics }) {
  const { db, limits, metrics: m } = deps;
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(eventRoute, async (c) => {
    const headers = c.req.valid('header');
    const device = headers['x-device-id'];
    const key = `events:${device ? `dev:${sha(device)}` : `ip:${sha(clientIp(c))}`}`;
    if (await limits.overPerMinute(key, EVENTS_PER_MINUTE))
      throw new ApiError('rate_limited', 'Too many events.');

    const event = c.req.valid('json');
    if (event.name === 'web_vital') {
      const attrs = { metric: event.metric, page: event.page, connection: event.connection ?? 'unknown' };
      if (event.metric === 'CLS') m.cls.record(event.value, attrs);
      else m.vitals.record(event.value / 1000, attrs);
    } else {
      const userId = c.var.user?.id ?? null;
      const platform = event.platform ?? (headers['x-client'] === 'web' ? 'web' : null);
      // INSERT … SELECT: an unknown activity stores nothing, rather than failing the beacon.
      await db
        .insertInto('events')
        .columns(['name', 'user_id', 'activity_id', 'generation', 'platform'])
        .expression((eb) =>
          eb
            .selectFrom('activities')
            .select([
              sql.lit('activity_viewed').as('name'),
              sql<string | null>`${userId}::uuid`.as('user_id'),
              'id',
              userId
                ? eb.selectFrom('users').select('invite_generation').where('id', '=', userId).as('generation')
                : sql<number | null>`NULL::int`.as('generation'),
              sql<string | null>`${platform}::text`.as('platform'),
            ])
            .where('id', '=', event.activityId),
        )
        .execute();
    }
    m.received.add(1, { name: event.name });
    return c.body(null, 204);
  });

  return app;
}
