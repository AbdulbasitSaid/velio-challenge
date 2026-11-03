import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { BookingResponse, IdempotencyKey } from '@velio/contracts';
import type { AppEnv } from '../../app';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import { toBooking, type BookingEngine } from './engine';

const bookRoute = createRoute({
  method: 'post',
  path: '/activities/{id}/bookings',
  summary: 'Book a spot (direct booking)',
  description:
    'Takes one spot and creates a Plan owned by the caller. Retrying with the same `Idempotency-Key` returns the original booking with `200` and books nothing more.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    params: z.object({ id: z.uuid() }),
    headers: z.object({
      'idempotency-key': IdempotencyKey,
      'x-client': z.enum(['web', 'mobile']).optional(),
    }),
  },
  responses: {
    201: { description: 'Booked', content: { 'application/json': { schema: BookingResponse } } },
    200: {
      description: 'Replay of an earlier request with the same key',
      content: { 'application/json': { schema: BookingResponse } },
    },
    400: errorResponse('`validation_failed`: missing or malformed `Idempotency-Key`'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: hosts cannot book their own activity'),
    404: errorResponse('`not_found`'),
    409: errorResponse(
      '`sold_out`, `already_booked`, `booking_removed`, `activity_started`, `bookings_paused` or `idempotency_conflict`',
    ),
  },
});

const removeRoute = createRoute({
  method: 'post',
  path: '/host/bookings/{id}/removal',
  summary: "Remove an attendee (the activity's host only)",
  description:
    'Frees the spot at once. Repeating it on a removed booking returns `200` and frees nothing more.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: { params: z.object({ id: z.uuid() }) },
  responses: {
    200: { description: 'Removed', content: { 'application/json': { schema: BookingResponse } } },
    400: errorResponse('`validation_failed`'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not the host'),
    404: errorResponse('`not_found`'),
  },
});

export function bookingRoutes(engine: BookingEngine) {
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(bookRoute, async (c) => {
    const headers = c.req.valid('header');
    const result = await engine.bookSpot({
      activityId: c.req.valid('param').id,
      userId: c.var.user!.id,
      idempotencyKey: headers['idempotency-key'],
      source: 'direct',
      platform: headers['x-client'],
    });
    return c.json(
      { booking: toBooking(result.booking), activity: result.activity },
      result.created ? 201 : 200,
    );
  });

  app.openapi(removeRoute, async (c) => {
    const result = await engine.removeBooking({ bookingId: c.req.valid('param').id, hostId: c.var.user!.id });
    return c.json({ booking: toBooking(result.booking), activity: result.activity }, 200);
  });

  return app;
}
