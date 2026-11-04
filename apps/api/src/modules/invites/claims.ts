import type { ClaimCreate } from '@velio/contracts';
import { sql } from 'kysely';
import type { Config } from '../../config';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import type { Logger } from '../../telemetry/logger';
import { NewUserConflict, type BookingEngine, type BookingResult } from '../bookings/engine';
import { contactHash, normaliseContact } from '../identity/contact';
import type { User } from '../identity/sessions';
import { createSession, type SessionPolicy } from '../identity/sessions';
import { normaliseCode } from './codes';
import type { Limits } from './limits';
import type { InviteMetrics } from './metrics';
import type { InviteService, LoadedInvite } from './service';

export interface ClaimDeps {
  db: Db;
  config: Config;
  logger: Logger;
  clock: () => Date;
  engine: BookingEngine;
  invites: InviteService;
  limits: Limits;
  metrics: InviteMetrics;
  policy: SessionPolicy;
}

export interface ClaimInput {
  rawCode: string;
  idempotencyKey: string;
  /** The caller's valid session user, if any. */
  sessionUser: User | null;
  body: ClaimCreate;
  deviceKey: string;
  deviceId?: string;
}

export interface ClaimResult {
  created: boolean;
  result: BookingResult;
  user: User;
  /** Set when the caller had no session: the new session's token. */
  token?: string;
}

type Identity = { kind: 'existing'; user: User } | { kind: 'new'; displayName: string; hash: Buffer };

/**
 * PRD I4, I6 (S4 §4.6): a claim is a booking through the S2 engine, with the invite claim, the
 * attribution or trust edge, a new guest and their session in the same transaction.
 */
export function createClaims(deps: ClaimDeps) {
  const { db, config, engine, invites, limits, metrics: m } = deps;

  async function reject(
    reason: string,
    invite: LoadedInvite | null,
    userId: string | null,
    platform?: string,
  ) {
    await engine.rejectClaim({
      reason,
      activityId: invite?.activity_id ?? null,
      userId,
      inviteId: invite?.id ?? null,
      platform,
    });
    if (reason === 'rate_limited') m.rateLimited.add(1, { scope: invite ? 'link' : 'code' });
    return new ApiError(
      reason as never,
      reason === 'rate_limited' && invite ? 'This link is busy. Try again in a minute.' : undefined,
    );
  }

  async function resolveIdentity(input: ClaimInput): Promise<Identity> {
    if (input.sessionUser) return { kind: 'existing', user: input.sessionUser };
    const { displayName, contact, country } = input.body;
    if (!displayName || !contact) {
      throw new ApiError('validation_failed', 'Invalid request: displayName, contact.');
    }
    const hash = contactHash(config.CONTACT_PEPPER, normaliseContact(contact, country));
    const user = await db.selectFrom('users').selectAll().where('contact_hash', '=', hash).executeTakeFirst();
    // R5: the first identity for a contact wins; its stored name is kept.
    return user ? { kind: 'existing', user } : { kind: 'new', displayName, hash };
  }

  async function userById(id: string): Promise<User> {
    return db.selectFrom('users').selectAll().where('id', '=', id).executeTakeFirstOrThrow();
  }

  async function activityState(activityId: string) {
    const row = await db
      .selectFrom('activities')
      .select(['spots_left', 'version'])
      .where('id', '=', activityId)
      .executeTakeFirstOrThrow();
    return { id: activityId, spotsLeft: row.spots_left, version: Number(row.version) };
  }

  /** An earlier result for this caller: their replay of the key, or their claim of this vouch. */
  async function earlier(invite: LoadedInvite, user: User, key: string): Promise<BookingResult | undefined> {
    const byKey = await db
      .selectFrom('bookings')
      .selectAll()
      .where('user_id', '=', user.id)
      .where('idempotency_key', '=', key)
      .executeTakeFirst();
    if (byKey) {
      if (byKey.activity_id !== invite.activity_id) throw new ApiError('idempotency_conflict');
      return { created: false, booking: byKey, activity: await activityState(byKey.activity_id) };
    }
    return undefined;
  }

  async function vouchClaimant(inviteId: string) {
    return db
      .selectFrom('invite_claims as c')
      .innerJoin('bookings as b', 'b.id', 'c.booking_id')
      .selectAll('b')
      .where('c.invite_id', '=', inviteId)
      .executeTakeFirst();
  }

  async function attempt(input: ClaimInput, invite: LoadedInvite, identity: Identity): Promise<ClaimResult> {
    const platform = input.body.platform;
    const existingUser = identity.kind === 'existing' ? identity.user : null;

    // FR-010 order after the code lookup: replay, expired, paused, vouch claimed, link limit.
    if (existingUser) {
      const replay = await earlier(invite, existingUser, input.idempotencyKey);
      if (replay) return finishReplay(input, replay, existingUser);
    }
    if (invite.expired) throw await reject('invite_expired', invite, existingUser?.id ?? null, platform);
    if (invite.paused) throw await reject('invite_paused', invite, existingUser?.id ?? null, platform);
    if (invite.rail === 'vouch') {
      const claimed = await vouchClaimant(invite.id);
      if (claimed) {
        // PRD Edge cases: "If it was claimed by her own device, show her booking instead."
        if (existingUser && claimed.user_id === existingUser.id) {
          return finishReplay(
            input,
            { created: false, booking: claimed, activity: await activityState(claimed.activity_id) },
            existingUser,
          );
        }
        throw await reject('already_claimed', invite, existingUser?.id ?? null, platform);
      }
    } else if (await limits.linkOverLimit(invite.id, config.LINK_CLAIMS_PER_MINUTE)) {
      throw await reject('rate_limited', invite, existingUser?.id ?? null, platform);
    }

    const inviter = await db
      .selectFrom('users')
      .select('invite_generation')
      .where('id', '=', invite.inviter_id)
      .executeTakeFirstOrThrow();
    const rail = invite.rail as 'vouch' | 'public';
    const claimerHash = existingUser ? existingUser.contact_hash : (identity as { hash: Buffer }).hash;
    const mismatch =
      rail === 'vouch' &&
      invite.invitee_contact_hash !== null &&
      !invite.invitee_contact_hash.equals(claimerHash);
    let token: string | undefined;

    const result = await engine.bookSpot({
      activityId: invite.activity_id,
      userId: existingUser?.id ?? '',
      newUser:
        identity.kind === 'new'
          ? {
              displayName: identity.displayName,
              contactHash: identity.hash,
              generation: inviter.invite_generation + 1,
            }
          : undefined,
      idempotencyKey: input.idempotencyKey,
      source: rail,
      planId: invite.plan_id,
      inviteId: invite.id,
      platform,
      async extend(tx, booking) {
        await tx
          .insertInto('invite_claims')
          .values({ booking_id: booking.id, invite_id: invite.id, rail })
          .execute();
        if (identity.kind === 'new') {
          // First claim sets inviter and generation forever (PRD I4, D4); the trigger chains it.
          await tx
            .insertInto('attributions')
            .values({
              invitee_id: booking.user_id,
              inviter_id: invite.inviter_id,
              invite_id: invite.id,
              rail,
              generation: inviter.invite_generation + 1,
            })
            .execute();
        } else if (rail === 'vouch') {
          // D4: a vouch for someone already on Velio is a trust edge, not a new attribution.
          await tx
            .insertInto('trust_edges')
            .values({ voucher_id: invite.inviter_id, vouchee_id: booking.user_id, invite_id: invite.id })
            .execute();
        }
        if (!input.sessionUser) {
          token = await createSession(tx, {
            userId: booking.user_id,
            deviceId: input.deviceId,
            now: deps.clock(),
            policy: deps.policy,
          });
        }
        const event = (name: string, isNewUser?: boolean) =>
          tx
            .insertInto('events')
            .values((eb) => ({
              name,
              user_id: booking.user_id,
              activity_id: invite.activity_id,
              invite_id: invite.id,
              rail,
              generation: eb
                .selectFrom('users')
                .select('invite_generation')
                .where('id', '=', booking.user_id),
              platform: platform ?? null,
              props:
                isNewUser === undefined
                  ? sql`'{}'::jsonb`
                  : sql`jsonb_build_object('is_new_user', ${isNewUser}::boolean)`,
            }))
            .execute();
        await event('invite_claimed', identity.kind === 'new');
        if (mismatch) await event('vouch_contact_mismatch');
      },
    });

    if (mismatch && result.created) {
      m.contactMismatch.add(1);
      deps.logger.warn({ invite_id: invite.id }, 'vouch claimed with a different contact');
    }
    return { created: result.created, result, user: await userById(result.booking.user_id), token };
  }

  async function finishReplay(input: ClaimInput, result: BookingResult, user: User): Promise<ClaimResult> {
    const token = input.sessionUser
      ? undefined
      : await createSession(db, {
          userId: user.id,
          deviceId: input.deviceId,
          now: deps.clock(),
          policy: deps.policy,
        });
    return { created: false, result, user, token };
  }

  async function claim(input: ClaimInput): Promise<ClaimResult> {
    const platform = input.body.platform;
    const sessionUserId = input.sessionUser?.id ?? null;
    if (await limits.deviceLocked(input.deviceKey))
      throw await reject('rate_limited', null, sessionUserId, platform);
    const code = normaliseCode(input.rawCode);
    const invite = code ? await invites.loadByCode(code) : undefined;
    if (!invite) {
      await limits.countInvalid(input.deviceKey);
      throw await reject('invalid_code', null, sessionUserId, platform);
    }

    const identity = await resolveIdentity(input);
    try {
      return await attempt(input, invite, identity);
    } catch (err) {
      if (!(err instanceof NewUserConflict)) throw err;
      // A parallel claim or sign-in created this contact first: claim as that user, once.
      const user = await db
        .selectFrom('users')
        .selectAll()
        .where('contact_hash', '=', (identity as { hash: Buffer }).hash)
        .executeTakeFirstOrThrow();
      return attempt(input, invite, { kind: 'existing', user });
    }
  }

  return { claim };
}

export type Claims = ReturnType<typeof createClaims>;
