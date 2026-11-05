import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { AdminActivityList, AdminAudit, AdminMetrics } from '@velio/contracts';
import { sql } from 'kysely';
import type { AppEnv } from '../../app';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import type { Jobs } from '../../jobs/jobs';
import { errorResponse } from '../../openapi';
import type { RollingWindow } from '../../telemetry/rolling';
import type { Limits } from '../invites/limits';
import { adminGuard } from './guard';
import { adminMetrics } from './metrics';

const ADMIN_SECURITY = [{ adminAuth: [] }];
const denied = {
  401: errorResponse('`unauthenticated`: missing or wrong admin token'),
  404: errorResponse('`not_found`: admin is not configured'),
  429: errorResponse('`rate_limited`: too many wrong tokens'),
};
const json = <T extends z.ZodType>(schema: T, description: string) => ({
  description,
  content: { 'application/json': { schema } },
});

const metricsRoute = createRoute({
  method: 'get',
  path: '/admin/metrics',
  summary: 'The PRD goals, funnel per rail, K-factor, guardrail and holdout split (admin)',
  security: ADMIN_SECURITY,
  request: { query: z.object({ days: z.coerce.number().int().min(1).max(90).default(7) }) },
  responses: { 200: json(AdminMetrics, 'Aggregates over the last `days`'), ...denied },
});

const activitiesRoute = createRoute({
  method: 'get',
  path: '/admin/activities',
  summary: 'Upcoming activities, with the kill switch state (admin)',
  security: ADMIN_SECURITY,
  responses: { 200: json(AdminActivityList, 'Soonest first, at most 200'), ...denied },
});

const pauseRoute = (action: 'pause' | 'resume') =>
  createRoute({
    method: 'post',
    path: `/admin/activities/{id}/${action}`,
    summary:
      action === 'pause'
        ? 'Kill switch: stop new bookings and claims for an activity (admin)'
        : 'Lift the kill switch (admin)',
    security: ADMIN_SECURITY,
    request: { params: z.object({ id: z.uuid() }) },
    responses: { 204: { description: 'Done; repeating it changes nothing' }, ...denied },
  });

const auditRoute = createRoute({
  method: 'post',
  path: '/admin/audit',
  summary: 'Verify every attribution and invite hash chain now (admin)',
  security: ADMIN_SECURITY,
  responses: { 200: json(AdminAudit, 'Chains that failed verification; empty when intact'), ...denied },
});

export function adminRoutes(deps: {
  db: Db;
  token: string | undefined;
  limits: Limits;
  jobs: Jobs;
  latency?: RollingWindow;
}) {
  const { db, jobs } = deps;
  const app = new OpenAPIHono<AppEnv>();
  app.use('/admin/*', adminGuard(deps.token, deps.limits));

  app.openapi(metricsRoute, async (c) =>
    c.json(
      await adminMetrics(db, {
        days: c.req.valid('query').days,
        latency: deps.latency,
        audit: jobs.lastAudit(),
      }),
      200,
    ),
  );

  app.openapi(activitiesRoute, async (c) => {
    const rows = await db
      .selectFrom('activities as a')
      .innerJoin('communities as c', 'c.id', 'a.community_id')
      .select([
        'a.id',
        'a.title',
        'c.name as community_name',
        'a.starts_at',
        'a.timezone',
        'a.capacity',
        'a.spots_left',
        'a.bookings_paused',
      ])
      .where('a.starts_at', '>', sql<Date>`now()`)
      .orderBy('a.starts_at')
      .limit(200)
      .execute();
    return c.json(
      {
        activities: rows.map((r) => ({
          id: r.id,
          title: r.title,
          communityName: r.community_name,
          startsAt: r.starts_at.toISOString(),
          timezone: r.timezone,
          capacity: r.capacity,
          spotsLeft: r.spots_left,
          bookingsPaused: r.bookings_paused,
        })),
      },
      200,
    );
  });

  for (const action of ['pause', 'resume'] as const) {
    app.openapi(pauseRoute(action), async (c) => {
      const id = c.req.valid('param').id;
      // The booking transaction's conditional UPDATE checks this flag, so it takes effect at once
      // for every booking and claim (PRD R1 fallback).
      const updated = await db
        .updateTable('activities')
        .set({ bookings_paused: action === 'pause' })
        .where('id', '=', id)
        .returning('id')
        .executeTakeFirst();
      if (!updated) throw new ApiError('not_found');
      c.var.logger.warn({ activity_id: id, action }, 'admin kill switch');
      return c.body(null, 204);
    });
  }

  app.openapi(auditRoute, async (c) => {
    const result = await jobs.audit();
    return c.json({ ranAt: result.ranAt.toISOString(), failures: result.failures }, 200);
  });

  return app;
}
