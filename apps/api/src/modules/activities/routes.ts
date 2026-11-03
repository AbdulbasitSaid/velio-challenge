import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { ActivityCreate, ActivityPatch, HostActivity } from '@velio/contracts';
import type { AppDeps, AppEnv } from '../../app';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import { createActivity, updateActivity } from './service';

const createActivityRoute = createRoute({
  method: 'post',
  path: '/activities',
  summary: 'Create an activity, hosted by the caller',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    body: { required: true, content: { 'application/json': { schema: ActivityCreate } } },
  },
  responses: {
    201: { description: 'Created', content: { 'application/json': { schema: HostActivity } } },
    400: errorResponse('`validation_failed`'),
    401: errorResponse('`unauthenticated`'),
    404: errorResponse('`not_found`: unknown community'),
  },
});

const updateActivityRoute = createRoute({
  method: 'patch',
  path: '/activities/{id}',
  summary: 'Edit an activity (host only)',
  description:
    'Date, time zone and location are locked once the activity has a confirmed booking. Capacity can be raised at any time and lowered down to the number of confirmed bookings.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    params: z.object({ id: z.uuid() }),
    body: { required: true, content: { 'application/json': { schema: ActivityPatch } } },
  },
  responses: {
    200: { description: 'Updated', content: { 'application/json': { schema: HostActivity } } },
    400: errorResponse('`validation_failed`'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not the host'),
    404: errorResponse('`not_found`'),
    409: errorResponse('`location_locked` or `capacity_below_bookings`'),
  },
});

export function activityRoutes(deps: AppDeps) {
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(createActivityRoute, async (c) => {
    const activity = await createActivity(deps.db, {
      hostId: c.var.user!.id,
      body: c.req.valid('json'),
      now: deps.clock(),
    });
    return c.json(activity, 201);
  });

  app.openapi(updateActivityRoute, async (c) => {
    const activity = await updateActivity(deps.db, {
      activityId: c.req.valid('param').id,
      userId: c.var.user!.id,
      patch: c.req.valid('json'),
      now: deps.clock(),
    });
    return c.json(activity, 200);
  });

  return app;
}
