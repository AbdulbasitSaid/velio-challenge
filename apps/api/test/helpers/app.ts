import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import type { Db } from '../../src/db/client';
import { createLogger } from '../../src/telemetry/logger';

export const TEST_PEPPER = 'test-pepper-not-a-secret-0123456789abcdef';

/** A movable clock for session-expiry tests. */
export function testClock(start = new Date('2026-11-03T12:00:00Z')) {
  let now = start.getTime();
  return {
    now: () => new Date(now),
    advanceDays(days: number) {
      now += days * 86_400_000;
    },
  };
}

export function testApp(db: Db, clock: () => Date = () => new Date(), env: Record<string, string> = {}) {
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: 'postgres://unused/unused',
    DATABASE_LISTEN_URL: 'postgres://unused/unused',
    CONTACT_PEPPER: TEST_PEPPER,
    ...env,
  });
  return createApp({ config, db, logger: createLogger('silent'), clock });
}

export function json(body: unknown, headers: Record<string, string> = {}): RequestInit {
  return {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  };
}

/** The `velio_session` value from a response's Set-Cookie header. */
export function sessionCookie(res: Response): string | undefined {
  const header = res.headers.get('set-cookie') ?? '';
  return /velio_session=([^;]*)/.exec(header)?.[1];
}
