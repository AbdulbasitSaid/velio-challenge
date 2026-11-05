import { createHash } from 'node:crypto';
import { sql } from 'kysely';
import type { Db } from '../../db/client';

/** PRD R10: invalid codes allowed per device per hour before every lookup is refused. */
export const INVALID_CODES_PER_HOUR = 10;

const HOUR_MS = 3_600_000;
const MINUTE_MS = 60_000;

const sha = (value: string) => createHash('sha256').update(value).digest('hex');

/** The rate-limit key for a caller: the device ID if sent, otherwise the client IP. Hashed. */
export function deviceKey(deviceId: string | undefined, ip: string): string {
  return deviceId ? `code:dev:${sha(deviceId)}` : `code:ip:${sha(ip)}`;
}

const windowStart = (now: Date, size: number) => new Date(Math.floor(now.getTime() / size) * size);

/** Fixed windows in `rate_limits` (MVP plan §4.7). */
export function createLimits(db: Db, clock: () => Date) {
  async function count(key: string, size: number): Promise<number> {
    const row = await db
      .selectFrom('rate_limits')
      .select('count')
      .where('key', '=', key)
      .where('window_start', '=', windowStart(clock(), size))
      .executeTakeFirst();
    return row?.count ?? 0;
  }

  async function increment(key: string, size: number): Promise<number> {
    const row = await db
      .insertInto('rate_limits')
      .values({ key, window_start: windowStart(clock(), size), count: 1 })
      .onConflict((oc) =>
        oc.columns(['key', 'window_start']).doUpdateSet({ count: sql<number>`rate_limits.count + 1` }),
      )
      .returning('count')
      .executeTakeFirstOrThrow();
    return row.count;
  }

  return {
    /** A device past its limit is refused for every code, so it can't tell valid from invalid. */
    async deviceLocked(key: string): Promise<boolean> {
      return (await count(key, HOUR_MS)) >= INVALID_CODES_PER_HOUR;
    },
    countInvalid: (key: string) => increment(key, HOUR_MS),
    /** Counts one claim attempt on a public link; true when it is over the per-minute limit. */
    async linkOverLimit(inviteId: string, perMinute: number): Promise<boolean> {
      return (await increment(`link:${inviteId}`, MINUTE_MS)) > perMinute;
    },
    /** Counts one request under `key`; true when it is over the per-minute limit (S8). */
    async overPerMinute(key: string, perMinute: number): Promise<boolean> {
      return (await increment(key, MINUTE_MS)) > perMinute;
    },
    /** This minute's count under `key`, without adding to it. */
    minuteCount: (key: string) => count(key, MINUTE_MS),
  };
}

export type Limits = ReturnType<typeof createLimits>;
