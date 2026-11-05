import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import {
  ClaimCreate,
  ClaimResponse,
  DeviceId,
  IdempotencyKey,
  Invite,
  InviteCreate,
  InviteView,
  OpenCreate,
} from '@velio/contracts';
import type { Context } from 'hono';
import type { AppEnv } from '../../app';
import { ApiError } from '../../errors';
import { errorResponse, SECURITY } from '../../openapi';
import { toBooking } from '../bookings/engine';
import { setSessionCookie, requireUser } from '../identity/middleware';
import { toMemberPerson } from '../identity/people';
import type { SessionPolicy } from '../identity/sessions';
import type { Claims } from './claims';
import { normaliseCode } from './codes';
import { deviceKey, type Limits } from './limits';
import type { InviteMetrics } from './metrics';
import type { InviteService } from './service';

/** Raw input: normalised (spaces, hyphens, case) before lookup. */
const CodeParam = z.object({ code: z.string().min(1).max(32) });

const createInviteRoute = createRoute({
  method: 'post',
  path: '/plans/{id}/invites',
  summary: 'Create a vouch, or get your public link (Plan members only)',
  description:
    'A vouch is single use and addressed to one named person; its contact is stored only as a keyed hash. A public link is multi use; each member has one per Plan, so asking again returns it with `200`.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    params: z.object({ id: z.uuid() }),
    headers: z.object({ 'x-client': z.enum(['web', 'mobile']).optional() }),
    body: { required: true, content: { 'application/json': { schema: InviteCreate } } },
  },
  responses: {
    201: { description: 'Created', content: { 'application/json': { schema: Invite } } },
    200: { description: 'Your existing public link', content: { 'application/json': { schema: Invite } } },
    400: errorResponse('`validation_failed` or `invalid_contact`'),
    401: errorResponse('`unauthenticated`'),
    403: errorResponse('`forbidden`: not a confirmed member of the Plan'),
    404: errorResponse('`not_found`'),
    409: errorResponse('`activity_started`'),
  },
});

const viewRoute = createRoute({
  method: 'get',
  path: '/invites/{code}',
  summary: 'The public invite page data',
  description:
    'No session needed. More than 10 unknown codes from one device in an hour lock that device out of every code until the hour ends (`rate_limited`).',
  request: {
    params: CodeParam,
    headers: z.object({ 'x-device-id': DeviceId.optional() }),
  },
  responses: {
    200: { description: 'The invite', content: { 'application/json': { schema: InviteView } } },
    404: errorResponse('`invalid_code`'),
    429: errorResponse('`rate_limited`'),
  },
});

const openRoute = createRoute({
  method: 'post',
  path: '/invites/{code}/opens',
  summary: 'Open beacon: send once the invite page has rendered',
  description:
    'Recorded at most once per invite per device. Preview bots and the Plan’s own members are not recorded. Always `204` for a known code.',
  request: {
    params: CodeParam,
    headers: z.object({ 'x-device-id': DeviceId }),
    body: { required: false, content: { 'application/json': { schema: OpenCreate } } },
  },
  responses: {
    204: { description: 'Received' },
    400: errorResponse('`validation_failed`: missing `X-Device-Id`'),
    404: errorResponse('`invalid_code`'),
    429: errorResponse('`rate_limited`'),
  },
});

const claimRoute = createRoute({
  method: 'post',
  path: '/invites/{code}/claims',
  summary: 'Claim a spot through an invite',
  description:
    'The same booking transaction as a direct booking. With a session, the body is ignored; without one, `displayName` and `contact` sign the guest in (web: cookie; `X-Client: mobile`: token in the body). Retrying with the same `Idempotency-Key` returns the original claim with `200`.',
  security: [...SECURITY, {}],
  request: {
    params: CodeParam,
    headers: z.object({
      'idempotency-key': IdempotencyKey,
      'x-client': z.enum(['web', 'mobile']).optional(),
      'x-device-id': DeviceId.optional(),
    }),
    body: { required: false, content: { 'application/json': { schema: ClaimCreate } } },
  },
  responses: {
    201: { description: 'Claimed', content: { 'application/json': { schema: ClaimResponse } } },
    200: {
      description: 'Replay, or this caller already claimed this vouch',
      content: { 'application/json': { schema: ClaimResponse } },
    },
    400: errorResponse('`validation_failed` or `invalid_contact`'),
    403: errorResponse('`forbidden`: the host cannot claim on their own activity'),
    404: errorResponse('`invalid_code`'),
    409: errorResponse(
      '`already_claimed`, `invite_paused`, `already_booked`, `booking_removed`, `bookings_paused`, `sold_out` or `idempotency_conflict`',
    ),
    410: errorResponse('`invite_expired`'),
    429: errorResponse('`rate_limited`'),
  },
});

const pauseRoute = (method: 'post' | 'delete') =>
  createRoute({
    method,
    path: '/invites/{code}/pause',
    summary: method === 'post' ? 'Pause a public link' : 'Resume a public link',
    description: "The link's creator or the activity's host. Vouch invites can't be paused.",
    security: SECURITY,
    middleware: [requireUser] as const,
    request: { params: CodeParam },
    responses: {
      204: { description: method === 'post' ? 'Paused' : 'Resumed' },
      400: errorResponse('`validation_failed`: not a public link'),
      401: errorResponse('`unauthenticated`'),
      403: errorResponse('`forbidden`'),
      404: errorResponse('`not_found`'),
    },
  });

/** Rightmost X-Forwarded-For entry: the one CloudFront added. Locally, the socket address. */
export function clientIp(c: Context<AppEnv>): string {
  const forwarded = c.req.header('x-forwarded-for');
  if (forwarded) return forwarded.split(',').at(-1)!.trim();
  const server = c.env as { requestIP?: (r: Request) => { address: string } | null } | undefined;
  return server?.requestIP?.(c.req.raw)?.address ?? 'unknown';
}

export interface InviteRouteDeps {
  invites: InviteService;
  claims: Claims;
  limits: Limits;
  metrics: InviteMetrics;
  policy: SessionPolicy;
}

export function inviteRoutes(deps: InviteRouteDeps) {
  const { invites, limits } = deps;
  const app = new OpenAPIHono<AppEnv>();

  /** The code lookup shared by view and open: device lockout first, then count unknown codes. */
  async function lookup(c: Context<AppEnv>, raw: string, deviceId: string | undefined) {
    const key = deviceKey(deviceId, clientIp(c));
    if (await limits.deviceLocked(key)) {
      deps.metrics.rateLimited.add(1, { scope: 'code' });
      throw new ApiError('rate_limited');
    }
    const code = normaliseCode(raw);
    const invite = code ? await invites.loadByCode(code) : undefined;
    if (!invite) {
      await limits.countInvalid(key);
      throw new ApiError('invalid_code');
    }
    return invite;
  }

  app.openapi(createInviteRoute, async (c) => {
    const { created, invite } = await invites.create({
      planId: c.req.valid('param').id,
      user: c.var.user!,
      body: c.req.valid('json'),
      platform: c.req.valid('header')['x-client'],
    });
    return c.json(invite, created ? 201 : 200);
  });

  app.openapi(viewRoute, async (c) => {
    const invite = await lookup(c, c.req.valid('param').code, c.req.valid('header')['x-device-id']);
    const view = (await invites.view(invite.code, c.var.user?.id ?? null))!;
    c.header('cache-control', 'no-store');
    return c.json(view, 200);
  });

  app.openapi(openRoute, async (c) => {
    const deviceId = c.req.valid('header')['x-device-id'];
    const invite = await lookup(c, c.req.valid('param').code, deviceId);
    const body = (await c.req.json().catch(() => ({}))) as { platform?: string };
    const platform = OpenCreate.safeParse(body).data?.platform;
    await invites.open({
      code: invite.code,
      deviceId,
      viewerId: c.var.user?.id ?? null,
      userAgent: c.req.header('user-agent') ?? '',
      platform,
    });
    return c.body(null, 204);
  });

  app.openapi(claimRoute, async (c) => {
    const headers = c.req.valid('header');
    const raw = await c.req.json().catch(() => ({}));
    const parsed = ClaimCreate.safeParse(raw);
    if (!parsed.success) throw new ApiError('validation_failed', 'Invalid request: body.');
    const result = await deps.claims.claim({
      rawCode: c.req.valid('param').code,
      idempotencyKey: headers['idempotency-key'],
      sessionUser: c.var.user,
      body: parsed.data,
      deviceKey: deviceKey(headers['x-device-id'], clientIp(c)),
      deviceId: headers['x-device-id'],
    });
    const mobile = headers['x-client'] === 'mobile';
    if (result.token && !mobile) setSessionCookie(c, result.token, deps.policy);
    return c.json(
      {
        booking: toBooking(result.result.booking),
        activity: result.result.activity,
        planId: result.result.booking.plan_id,
        user: toMemberPerson(result.user),
        ...(result.token && mobile && { token: result.token }),
      },
      result.created ? 201 : 200,
    );
  });

  for (const method of ['post', 'delete'] as const) {
    app.openapi(pauseRoute(method), async (c) => {
      const code = normaliseCode(c.req.valid('param').code);
      if (!code) throw new ApiError('not_found');
      await invites.setPaused({ code, userId: c.var.user!.id, paused: method === 'post' });
      return c.body(null, 204);
    });
  }

  return app;
}
