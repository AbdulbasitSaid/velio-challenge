import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { ErrorEnvelope, MemberPerson, SessionCreate, SessionResponse } from '@velio/contracts';
import type { AppDeps, AppEnv } from '../../app';
import { ApiError } from '../../errors';
import { contactHash, normaliseContact } from './contact';
import {
  clearSessionCookie,
  presentedToken,
  requireUser,
  sessionPolicy,
  setSessionCookie,
} from './middleware';
import { toMemberPerson } from './people';
import { createSession, revokeSession } from './sessions';

const SECURITY: Record<string, string[]>[] = [{ cookieAuth: [] }, { bearerAuth: [] }];

const errorResponse = (description: string) => ({
  description,
  content: { 'application/json': { schema: ErrorEnvelope } },
});

const createSessionRoute = createRoute({
  method: 'post',
  path: '/sessions',
  summary: 'Continue as: sign in or sign up with a name and an email or phone',
  description:
    'Always issues a new session and revokes any session sent with the request. Web clients get an httpOnly cookie; clients sending `X-Client: mobile` get the token in the body.',
  request: {
    headers: z.object({
      'x-client': z.enum(['web', 'mobile']).optional(),
      'x-device-id': z.string().max(128).optional(),
    }),
    body: { required: true, content: { 'application/json': { schema: SessionCreate } } },
  },
  responses: {
    201: { description: 'Signed in', content: { 'application/json': { schema: SessionResponse } } },
    400: errorResponse('`invalid_contact` or `validation_failed`'),
  },
});

const meRoute = createRoute({
  method: 'get',
  path: '/me',
  summary: 'The signed-in person',
  security: SECURITY,
  middleware: [requireUser] as const,
  responses: {
    200: { description: 'The caller', content: { 'application/json': { schema: MemberPerson } } },
    401: errorResponse('`unauthenticated`'),
  },
});

const signOutRoute = createRoute({
  method: 'delete',
  path: '/sessions/current',
  summary: 'Sign out: revoke the current session',
  security: SECURITY,
  middleware: [requireUser] as const,
  responses: {
    204: { description: 'Signed out' },
    401: errorResponse('`unauthenticated`'),
  },
});

export function identityRoutes(deps: AppDeps) {
  const { db, config } = deps;
  const policy = sessionPolicy(config);
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(createSessionRoute, async (c) => {
    const body = c.req.valid('json');
    const headers = c.req.valid('header');
    const hash = contactHash(config.CONTACT_PEPPER, normaliseContact(body.contact, body.country));
    const now = deps.clock();

    // Rotation: a session sent with this request is revoked, so it can't be fixed in advance.
    const previous = presentedToken(c);
    if (previous) await revokeSession(db, previous.token);

    // Find or create. ON CONFLICT keeps this safe when two first sign-ins race.
    const user =
      (await db
        .insertInto('users')
        .values({ display_name: body.displayName, contact_hash: hash })
        .onConflict((oc) => oc.column('contact_hash').doNothing())
        .returningAll()
        .executeTakeFirst()) ??
      (await db.selectFrom('users').selectAll().where('contact_hash', '=', hash).executeTakeFirstOrThrow());

    const token = await createSession(db, {
      userId: user.id,
      deviceId: headers['x-device-id'],
      now,
      policy,
    });

    if (headers['x-client'] === 'mobile') {
      return c.json({ user: toMemberPerson(user), token }, 201);
    }
    setSessionCookie(c, token, policy);
    return c.json({ user: toMemberPerson(user) }, 201);
  });

  app.openapi(meRoute, (c) => {
    const user = c.var.user;
    if (!user) throw new ApiError('unauthenticated');
    return c.json(toMemberPerson(user), 200);
  });

  app.openapi(signOutRoute, async (c) => {
    const presented = presentedToken(c);
    if (presented) await revokeSession(db, presented.token);
    clearSessionCookie(c);
    return c.body(null, 204);
  });

  return app;
}
