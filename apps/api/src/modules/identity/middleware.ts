import type { Context } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import { createMiddleware } from 'hono/factory';
import type { AppDeps, AppEnv } from '../../app';
import { ApiError } from '../../errors';
import { resolveSession, type SessionPolicy } from './sessions';

export const SESSION_COOKIE = 'velio_session';

/** Tokens are 43 base64url characters; anything far longer is not worth hashing. */
const MAX_TOKEN_LENGTH = 128;

export function sessionPolicy(config: AppDeps['config']): SessionPolicy {
  return { idleDays: config.SESSION_IDLE_DAYS, absoluteDays: config.SESSION_ABSOLUTE_DAYS };
}

export function setSessionCookie(c: Context, token: string, policy: SessionPolicy) {
  setCookie(c, SESSION_COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: 'Lax',
    path: '/',
    maxAge: policy.idleDays * 86_400,
  });
}

export function clearSessionCookie(c: Context) {
  deleteCookie(c, SESSION_COOKIE, { httpOnly: true, secure: true, sameSite: 'Lax', path: '/' });
}

/** The presented token: `Authorization: Bearer` (mobile) first, then the session cookie (web). */
export function presentedToken(c: Context): { token: string; fromCookie: boolean } | undefined {
  const auth = c.req.header('authorization');
  if (auth?.startsWith('Bearer ')) {
    const token = auth.slice('Bearer '.length).trim();
    if (token && token.length <= MAX_TOKEN_LENGTH) return { token, fromCookie: false };
    return undefined;
  }
  const cookie = getCookie(c, SESSION_COOKIE);
  if (cookie && cookie.length <= MAX_TOKEN_LENGTH) return { token: cookie, fromCookie: true };
  return undefined;
}

/** Resolves the caller on every request. Sets `user` to null when there is no valid session. */
export function sessionMiddleware(deps: AppDeps) {
  const policy = sessionPolicy(deps.config);
  return createMiddleware<AppEnv>(async (c, next) => {
    c.set('user', null);
    const presented = presentedToken(c);
    if (presented) {
      const session = await resolveSession(deps.db, presented.token, deps.clock(), policy);
      if (session) {
        c.set('user', session.user);
        if (session.renewed && presented.fromCookie) setSessionCookie(c, presented.token, policy);
      }
    }
    await next();
  });
}

/** Route guard for `authenticated` routes. */
export const requireUser = createMiddleware<AppEnv>(async (c, next) => {
  if (!c.var.user) throw new ApiError('unauthenticated');
  await next();
});
