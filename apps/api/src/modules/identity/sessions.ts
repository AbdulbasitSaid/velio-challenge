import { createHash, randomBytes } from 'node:crypto';
import type { Selectable } from 'kysely';
import type { Db } from '../../db/client';
import type { Users } from '../../db/types';

const DAY_MS = 86_400_000;

/** A session is renewed (its idle expiry extended) at most once per this interval. */
export const RENEWAL_INTERVAL_MS = DAY_MS;

export interface SessionPolicy {
  idleDays: number;
  absoluteDays: number;
}

export type User = Selectable<Users>;

export function newToken(): string {
  return randomBytes(32).toString('base64url');
}

/** Only this hash is stored; the token itself never touches the database. */
export function hashToken(token: string): Buffer {
  return createHash('sha256').update(token).digest();
}

export async function createSession(
  db: Db,
  input: { userId: string; deviceId?: string; now: Date; policy: SessionPolicy },
): Promise<string> {
  const token = newToken();
  const { now, policy } = input;
  await db
    .insertInto('sessions')
    .values({
      token_hash: hashToken(token),
      user_id: input.userId,
      device_id: input.deviceId ?? null,
      created_at: now,
      last_renewed_at: now,
      expires_at: new Date(now.getTime() + policy.idleDays * DAY_MS),
      absolute_expires_at: new Date(now.getTime() + policy.absoluteDays * DAY_MS),
    })
    .execute();
  return token;
}

/**
 * Returns the session's user, or undefined when the token is unknown or past either expiry.
 * Extends the idle expiry when the last renewal was at least a day ago, never past the absolute
 * expiry. `renewed` tells the caller to refresh the cookie.
 */
export async function resolveSession(
  db: Db,
  token: string,
  now: Date,
  policy: SessionPolicy,
): Promise<{ user: User; renewed: boolean } | undefined> {
  const tokenHash = hashToken(token);
  const row = await db
    .selectFrom('sessions')
    .innerJoin('users', 'users.id', 'sessions.user_id')
    .selectAll('users')
    .select(['sessions.expires_at', 'sessions.absolute_expires_at', 'sessions.last_renewed_at'])
    .where('sessions.token_hash', '=', tokenHash)
    .executeTakeFirst();
  if (!row) return undefined;
  if (now >= row.expires_at || now >= row.absolute_expires_at) return undefined;

  const { expires_at, absolute_expires_at, last_renewed_at, ...user } = row;
  if (now.getTime() - last_renewed_at.getTime() < RENEWAL_INTERVAL_MS) return { user, renewed: false };

  const idleExpiry = new Date(now.getTime() + policy.idleDays * DAY_MS);
  await db
    .updateTable('sessions')
    .set({
      expires_at: idleExpiry < absolute_expires_at ? idleExpiry : absolute_expires_at,
      last_renewed_at: now,
    })
    .where('token_hash', '=', tokenHash)
    .execute();
  return { user, renewed: true };
}

export async function revokeSession(db: Db, token: string): Promise<void> {
  await db.deleteFrom('sessions').where('token_hash', '=', hashToken(token)).execute();
}

/** Deletes sessions past either expiry. Scheduled with the other jobs in S8. */
export async function deleteExpiredSessions(db: Db, now: Date): Promise<number> {
  const result = await db
    .deleteFrom('sessions')
    .where((eb) => eb.or([eb('expires_at', '<=', now), eb('absolute_expires_at', '<=', now)]))
    .executeTakeFirst();
  return Number(result.numDeletedRows);
}
