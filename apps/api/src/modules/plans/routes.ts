import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { MyPlans, PlanView } from '@velio/contracts';
import type { AppEnv } from '../../app';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import type { PlanService } from './service';

const planRoute = createRoute({
  method: 'get',
  path: '/plans/{id}',
  summary: 'A Plan: members, how each joined, and invite status (members only)',
  description:
    'Full names, because only people with a booking in the Plan can read it. Codes, links and notes appear only on invites the caller created. A removed member sees their removal and no invites.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'The Plan', content: { 'application/json': { schema: PlanView } } },
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: no booking in this Plan'),
    404: errorResponse('`not_found`'),
  },
});

const myPlansRoute = createRoute({
  method: 'get',
  path: '/me/plans',
  summary: "My plans: the caller's Plans, upcoming and past",
  security: SECURITY,
  middleware: [requireUser] as const,
  responses: {
    200: {
      description: 'Upcoming soonest first, past most recent first',
      content: { 'application/json': { schema: MyPlans } },
    },
    401: errorResponse('`unauthenticated`'),
  },
});

export function planRoutes(plans: PlanService) {
  const app = new OpenAPIHono<AppEnv>();
  app.openapi(planRoute, async (c) => c.json(await plans.view(c.req.valid('param').id, c.var.user!.id), 200));
  app.openapi(myPlansRoute, async (c) => c.json(await plans.mine(c.var.user!.id), 200));
  return app;
}
