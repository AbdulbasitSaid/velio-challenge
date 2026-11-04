import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { ActivityCreate, ActivityPatch, HostActivity, PublicActivity } from '@velio/contracts';
import type { AppDeps, AppEnv } from '../../app';
import { ApiError } from '../../errors';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import { createActivity, updateActivity } from './service';
import { buildSnapshot } from './snapshot';
import { staticMapUrl } from '../maps/static';
import type { PhotoStore } from '../uploads/photos';

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
    400: errorResponse('`validation_failed`, including a `photoKey` the caller did not upload'),
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
    400: errorResponse('`validation_failed`, including a `photoKey` the caller did not upload'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not the host'),
    404: errorResponse('`not_found`'),
    409: errorResponse('`location_locked` or `capacity_below_bookings`'),
  },
});

const snapshotRoute = createRoute({
  method: 'get',
  path: '/activities/{id}',
  summary: 'Public activity snapshot: details, live spots and version',
  description:
    "No session needed. With one, `viewer` gives the caller's own booking. Clients fetch this on every (re)connect of the realtime socket and poll it every 10 s while disconnected; `spots` events with a higher `version` replace its count.",
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'The snapshot', content: { 'application/json': { schema: PublicActivity } } },
    400: errorResponse('`validation_failed`'),
    404: errorResponse('`not_found`'),
  },
});

export function activityRoutes(deps: AppDeps, photos: PhotoStore) {
  const app = new OpenAPIHono<AppEnv>();
  const mapUrl = staticMapUrl(deps.config);

  /** FR-014: only a photo the caller uploaded can be attached. */
  async function assertOwnPhoto(photoKey: string | null | undefined, userId: string) {
    if (photoKey && !(await photos.isUploadedBy(photoKey, userId))) {
      throw new ApiError('validation_failed', 'Invalid request: photoKey.');
    }
  }

  app.openapi(snapshotRoute, async (c) => {
    const snapshot = await buildSnapshot(deps.db, c.req.valid('param').id, c.var.user?.id ?? null, mapUrl);
    if (!snapshot) throw new ApiError('not_found');
    c.header('cache-control', 'no-store');
    return c.json(snapshot, 200);
  });

  app.openapi(createActivityRoute, async (c) => {
    await assertOwnPhoto(c.req.valid('json').photoKey, c.var.user!.id);
    const activity = await createActivity(deps.db, {
      hostId: c.var.user!.id,
      body: c.req.valid('json'),
      now: deps.clock(),
    });
    return c.json(activity, 201);
  });

  app.openapi(updateActivityRoute, async (c) => {
    await assertOwnPhoto(c.req.valid('json').photoKey, c.var.user!.id);
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
