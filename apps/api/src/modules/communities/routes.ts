import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { CommunityList, CommunityPage, NextSteps, Profile } from '@velio/contracts';
import type { AppEnv } from '../../app';
import { errorResponse } from '../../openapi';
import type { CommunityService } from './service';

const listRoute = createRoute({
  method: 'get',
  path: '/communities',
  summary: 'Every community',
  responses: {
    200: { description: 'Communities', content: { 'application/json': { schema: CommunityList } } },
  },
});

const pageRoute = createRoute({
  method: 'get',
  path: '/communities/{slug}',
  summary: 'A community and its upcoming activities, with coordinates for the map',
  request: { params: z.object({ slug: z.string().min(1).max(100) }) },
  responses: {
    200: { description: 'The community page', content: { 'application/json': { schema: CommunityPage } } },
    404: errorResponse('`not_found`'),
  },
});

const profileRoute = createRoute({
  method: 'get',
  path: '/users/{id}/profile',
  summary: 'A public profile: name, "On Velio since", upcoming hosted activities',
  description: 'Never bookings or Plans: where someone will be is a safety concern (PRD Q10).',
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'The profile', content: { 'application/json': { schema: Profile } } },
    404: errorResponse('`not_found`'),
  },
});

const nextStepsRoute = createRoute({
  method: 'get',
  path: '/activities/{id}/next-steps',
  summary: 'The host\'s other dates and "More in [community]", for sold-out and expired screens',
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'Next steps', content: { 'application/json': { schema: NextSteps } } },
    404: errorResponse('`not_found`'),
  },
});

export function communityRoutes(communities: CommunityService) {
  const app = new OpenAPIHono<AppEnv>();
  app.openapi(listRoute, async (c) => c.json(await communities.list(), 200));
  app.openapi(pageRoute, async (c) => c.json(await communities.page(c.req.valid('param').slug), 200));
  app.openapi(profileRoute, async (c) => c.json(await communities.profile(c.req.valid('param').id), 200));
  app.openapi(nextStepsRoute, async (c) => c.json(await communities.nextSteps(c.req.valid('param').id), 200));
  return app;
}
