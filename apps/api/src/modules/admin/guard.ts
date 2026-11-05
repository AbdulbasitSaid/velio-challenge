import { createHash, timingSafeEqual } from 'node:crypto';
import { createMiddleware } from 'hono/factory';
import type { AppEnv } from '../../app';
import { ApiError } from '../../errors';
import type { Limits } from '../invites/limits';
import { clientIp } from '../invites/routes';

/** Wrong tokens allowed per IP per minute before every admin request is refused (SEC-001). */
export const ADMIN_FAILURES_PER_MINUTE = 10;

const digest = (value: string) => createHash('sha256').update(value).digest();

/**
 * S8 FR-010: `/api/admin/*` needs `Authorization: Bearer <ADMIN_TOKEN>`. Without a configured token
 * the routes don't exist (404). Both sides are hashed first, so the comparison is constant-time
 * whatever the lengths. The token is never logged.
 */
export function adminGuard(token: string | undefined, limits: Limits) {
  const expected = token ? digest(token) : undefined;
  return createMiddleware<AppEnv>(async (c, next) => {
    if (!expected) throw new ApiError('not_found');
    const key = `admin:ip:${createHash('sha256').update(clientIp(c)).digest('hex')}`;
    if ((await limits.minuteCount(key)) >= ADMIN_FAILURES_PER_MINUTE)
      throw new ApiError('rate_limited', 'Too many attempts. Try again in a minute.');
    const header = c.req.header('authorization') ?? '';
    const given = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!given || !timingSafeEqual(digest(given), expected)) {
      await limits.overPerMinute(key, ADMIN_FAILURES_PER_MINUTE);
      throw new ApiError('unauthenticated', 'Admin token required.');
    }
    await next();
  });
}
