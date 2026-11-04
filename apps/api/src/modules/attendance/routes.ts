import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { Attendance, AttendanceMarkCreate, Attendee, HostActivityList } from '@velio/contracts';
import type { AppEnv } from '../../app';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import type { AttendanceService } from './service';

const hostedRoute = createRoute({
  method: 'get',
  path: '/host/activities',
  summary: "The caller's hosted activities, upcoming and past",
  security: SECURITY,
  middleware: [requireUser] as const,
  responses: {
    200: { description: 'Hosted activities', content: { 'application/json': { schema: HostActivityList } } },
    401: errorResponse('`unauthenticated`'),
  },
});

const attendanceRoute = createRoute({
  method: 'get',
  path: '/host/activities/{id}/attendance',
  summary: 'Live attendance (the host only)',
  description: 'Names, refs, sources and the inviter; never contacts or invite notes (PRD D5).',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'Attendance', content: { 'application/json': { schema: Attendance } } },
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not the host'),
    404: errorResponse('`not_found`'),
  },
});

const markRoute = createRoute({
  method: 'post',
  path: '/host/bookings/{id}/attendance',
  summary: 'Mark an attendee attended or no-show (the host, after the start)',
  description: 'A later mark supersedes an earlier one; both are kept.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    params: z.object({ id: z.uuid() }),
    body: { required: true, content: { 'application/json': { schema: AttendanceMarkCreate } } },
  },
  responses: {
    200: {
      description: 'The attendee with the new mark',
      content: { 'application/json': { schema: Attendee } },
    },
    400: errorResponse('`validation_failed`'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not the host'),
    404: errorResponse('`not_found`'),
    409: errorResponse('`activity_not_started` or `booking_removed`'),
  },
});

export function attendanceRoutes(attendance: AttendanceService) {
  const app = new OpenAPIHono<AppEnv>();
  app.openapi(hostedRoute, async (c) => c.json(await attendance.hosted(c.var.user!.id), 200));
  app.openapi(attendanceRoute, async (c) =>
    c.json(await attendance.list(c.req.valid('param').id, c.var.user!.id), 200),
  );
  app.openapi(markRoute, async (c) =>
    c.json(await attendance.mark(c.req.valid('param').id, c.var.user!.id, c.req.valid('json').mark), 200),
  );
  return app;
}
