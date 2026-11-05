import type { Invite, InviteCreate, InviteView } from '@velio/contracts';
import { sql, type Selectable } from 'kysely';
import { createHoldout } from '../flags/holdout';
import type { Config } from '../../config';
import type { Db } from '../../db/client';
import type { Invites } from '../../db/types';
import { ApiError } from '../../errors';
import type { Logger } from '../../telemetry/logger';
import { buildSnapshot } from '../activities/snapshot';
import { staticMapUrl } from '../maps/static';
import { contactHash, normaliseContact } from '../identity/contact';
import { toMemberPerson, toPublicPerson } from '../identity/people';
import { notifyPlan } from '../realtime/notify';
import { inviteLink, newInviteCode } from './codes';
import type { InviteMetrics } from './metrics';

export type InviteRow = Selectable<Invites>;
type Rail = 'vouch' | 'public';
type PauseReason = 'owner' | 'host' | 'auto';

const CODE_ATTEMPTS = 5;
/** PRD R7: claims ÷ opens below this, over the trailing hour, pauses a busy public link. */
export const AUTO_PAUSE_CLAIM_RATE = 0.02;

/**
 * Backup filter for link-preview fetchers (PRD R9). Opens come from a client beacon after first
 * paint, which preview bots don't run; this catches the ones that do execute scripts.
 */
const PREVIEW_BOT =
  /WhatsApp|facebookexternalhit|Facebot|Twitterbot|Slackbot|TelegramBot|Discordbot|LinkedInBot|SkypeUriPreview|Googlebot|bingbot|Applebot|bot\b|crawler|spider/i;

export interface InviteDeps {
  db: Db;
  config: Config;
  logger: Logger;
  metrics: InviteMetrics;
}

export interface InviteStats {
  opens: number;
  claims: number;
  paused: boolean;
  pausedReason: PauseReason | null;
}

/** Opens, claims and pause state for many invites in one query. */
export async function inviteStats(db: Db, ids: string[]): Promise<Map<string, InviteStats>> {
  const out = new Map<string, InviteStats>();
  if (ids.length === 0) return out;
  const rows = await db
    .selectFrom('invites as i')
    .leftJoin('invite_controls as ic', 'ic.invite_id', 'i.id')
    .select([
      'i.id',
      sql<number>`(SELECT count(*)::int FROM invite_opens o WHERE o.invite_id = i.id)`.as('opens'),
      sql<number>`(SELECT count(*)::int FROM invite_claims c WHERE c.invite_id = i.id)`.as('claims'),
      sql<boolean>`coalesce(ic.paused, false)`.as('paused'),
      'ic.paused_reason',
    ])
    .where('i.id', 'in', ids)
    .execute();
  for (const r of rows) {
    out.set(r.id, {
      opens: r.opens,
      claims: r.claims,
      paused: r.paused,
      pausedReason: r.paused ? ((r.paused_reason as PauseReason | null) ?? null) : null,
    });
  }
  return out;
}

/** PRD Lifecycles (Invite), as the Plan shows it. */
export function planInviteStatus(rail: Rail, stats: InviteStats, started: boolean) {
  if (rail === 'vouch' && stats.claims > 0) return 'claimed' as const;
  if (started) return 'expired' as const;
  if (stats.claims > 0) return 'claimed' as const;
  if (stats.opens > 0) return 'opened' as const;
  return 'created' as const;
}

export function createInviteService(deps: InviteDeps) {
  const { db, config, metrics: m } = deps;
  const mapUrl = staticMapUrl(config);
  const holdout = createHoldout(db, config.HOLDOUT_PERCENT);

  async function loadByCode(code: string) {
    return db
      .selectFrom('invites as i')
      .innerJoin('users as u', 'u.id', 'i.inviter_id')
      .innerJoin('activities as a', 'a.id', 'i.activity_id')
      .leftJoin('invite_controls as ic', 'ic.invite_id', 'i.id')
      .selectAll('i')
      .select([
        'u.display_name as inviter_name',
        sql<boolean>`coalesce(ic.paused, false)`.as('paused'),
        'ic.paused_reason',
        // Invites expire at the activity's start (PRD Lifecycles). expires_at holds the same
        // instant, since the start time locks once anyone has booked; the activity is the source.
        sql<boolean>`a.starts_at <= now()`.as('expired'),
      ])
      .where('i.code', '=', code)
      .executeTakeFirst();
  }

  async function toInvite(row: InviteRow, createdBy: { id: string; display_name: string }): Promise<Invite> {
    const stats = (await inviteStats(db, [row.id])).get(row.id)!;
    const started = row.expires_at !== null && row.expires_at <= new Date();
    return {
      id: row.id,
      code: row.code,
      link: inviteLink(config.PUBLIC_BASE_URL, row.code),
      rail: row.rail as Rail,
      inviteeName: row.invitee_name,
      note: row.note,
      status: planInviteStatus(row.rail as Rail, stats, started),
      ...stats,
      createdBy: toMemberPerson(createdBy),
      createdAt: row.created_at.toISOString(),
    };
  }

  /**
   * PRD I1, I2 (FR-001–FR-004). Any confirmed Plan member, before start. A member's public link is
   * reused rather than duplicated. The insert's trigger extends the activity's hash chain.
   */
  async function create(input: {
    planId: string;
    user: { id: string; display_name: string };
    body: InviteCreate;
    platform?: string;
  }): Promise<{ created: boolean; invite: Invite }> {
    const { planId, user, body } = input;
    const plan = await db
      .selectFrom('plans as p')
      .innerJoin('activities as a', 'a.id', 'p.activity_id')
      .select(['p.activity_id', 'a.starts_at', sql<boolean>`a.starts_at <= now()`.as('started')])
      .where('p.id', '=', planId)
      .executeTakeFirst();
    if (!plan) throw new ApiError('not_found');
    const member = await db
      .selectFrom('bookings')
      .select('id')
      .where('plan_id', '=', planId)
      .where('user_id', '=', user.id)
      .where('status', '=', 'confirmed')
      .executeTakeFirst();
    if (!member) throw new ApiError('forbidden', 'Only people going can invite to this Plan.');
    if (plan.started) throw new ApiError('activity_started');
    // The server enforces the holdout, not just the UI (S8 FR-003).
    if ((await holdout.expose(user.id)) === 'holdout') throw new ApiError('invites_unavailable');

    const existingPublic = () =>
      db
        .selectFrom('invites')
        .selectAll()
        .where('plan_id', '=', planId)
        .where('inviter_id', '=', user.id)
        .where('rail', '=', 'public')
        .executeTakeFirst();
    if (body.rail === 'public') {
      const existing = await existingPublic();
      if (existing) return { created: false, invite: await toInvite(existing, user) };
    }

    const contact =
      body.rail === 'vouch' && body.contact
        ? contactHash(config.CONTACT_PEPPER, normaliseContact(body.contact, body.country))
        : null;

    const row = await db.transaction().execute(async (tx) => {
      for (let attempt = 0; attempt < CODE_ATTEMPTS; attempt++) {
        // DO NOTHING covers both a code collision and a parallel first public link.
        const inserted = await tx
          .insertInto('invites')
          .values({
            code: newInviteCode(),
            rail: body.rail,
            activity_id: plan.activity_id,
            plan_id: planId,
            inviter_id: user.id,
            invitee_name: body.rail === 'vouch' ? body.inviteeName : null,
            invitee_contact_hash: contact,
            note: body.rail === 'vouch' ? body.note || null : null,
            expires_at: plan.starts_at,
          })
          .onConflict((oc) => oc.doNothing())
          .returningAll()
          .executeTakeFirst();
        if (inserted) {
          await tx
            .insertInto('events')
            .values((eb) => ({
              name: 'invite_created',
              user_id: user.id,
              activity_id: plan.activity_id,
              invite_id: inserted.id,
              rail: body.rail,
              generation: eb.selectFrom('users').select('invite_generation').where('id', '=', user.id),
              platform: input.platform ?? null,
            }))
            .execute();
          await notifyPlan(tx, planId);
          return inserted;
        }
        if (body.rail === 'public') return undefined;
      }
      throw new Error(`invite code collided ${CODE_ATTEMPTS} times`);
    });
    if (!row) {
      // A parallel request created this member's public link first.
      return { created: false, invite: await toInvite((await existingPublic())!, user) };
    }
    m.created.add(1, { rail: body.rail });
    return { created: true, invite: await toInvite(row, user) };
  }

  /** PRD Flows, Lifecycles (FR-005). Precedence: claimed (vouch) > expired > paused > claimable. */
  async function view(code: string, viewerId: string | null): Promise<InviteView | undefined> {
    const invite = await loadByCode(code);
    if (!invite) return undefined;
    const claimant =
      invite.rail === 'vouch'
        ? await db
            .selectFrom('invite_claims as c')
            .innerJoin('bookings as b', 'b.id', 'c.booking_id')
            .select('b.user_id')
            .where('c.invite_id', '=', invite.id)
            .executeTakeFirst()
        : undefined;
    const activity = (await buildSnapshot(db, invite.activity_id, viewerId, mapUrl))!;
    const status = claimant ? 'claimed' : invite.expired ? 'expired' : invite.paused ? 'paused' : 'claimable';
    return {
      code: invite.code,
      rail: invite.rail as Rail,
      status,
      pausedReason: invite.paused ? ((invite.paused_reason as PauseReason | null) ?? null) : null,
      inviter: toPublicPerson({ id: invite.inviter_id, display_name: invite.inviter_name }),
      note: invite.rail === 'vouch' ? invite.note : null,
      claimedByViewer: claimant !== undefined && viewerId !== null && claimant.user_id === viewerId,
      activity,
    };
  }

  /** R7: after a recorded open on a public link, pause it if it is busy and almost nobody claims. */
  async function maybeAutoPause(inviteId: string, planId: string) {
    const [row] = (
      await sql<{ opens: number; claims: number }>`
        SELECT (SELECT count(*)::int FROM invite_opens
                 WHERE invite_id = ${inviteId} AND first_rendered_at > now() - interval '1 hour') AS opens,
               (SELECT count(*)::int FROM invite_claims
                 WHERE invite_id = ${inviteId} AND claimed_at > now() - interval '1 hour') AS claims`.execute(
        db,
      )
    ).rows;
    if (!row || row.opens < config.AUTO_PAUSE_MIN_OPENS) return;
    if (row.claims / row.opens >= AUTO_PAUSE_CLAIM_RATE) return;
    const paused = await db.transaction().execute(async (tx) => {
      const changed = await tx
        .insertInto('invite_controls')
        .values({ invite_id: inviteId, paused: true, paused_by: null, paused_reason: 'auto' })
        .onConflict((oc) =>
          oc
            .column('invite_id')
            .doUpdateSet({ paused: true, paused_by: null, paused_reason: 'auto', updated_at: sql`now()` })
            .where('invite_controls.paused', '=', false),
        )
        .returning('invite_id')
        .executeTakeFirst();
      if (changed) await notifyPlan(tx, planId);
      return changed !== undefined;
    });
    if (paused) {
      m.autoPaused.add(1);
      deps.logger.warn({ invite_id: inviteId }, 'public link auto-paused (R7)');
    }
  }

  /** Scope challenge 2, R9 (FR-006). Always succeeds for a known code; what it records varies. */
  async function open(input: {
    code: string;
    deviceId: string;
    viewerId: string | null;
    userAgent: string;
    platform?: string;
  }): Promise<boolean> {
    const invite = await loadByCode(input.code);
    if (!invite) return false;
    const rail = invite.rail as Rail;
    if (PREVIEW_BOT.test(input.userAgent)) {
      m.opens.add(1, { rail, outcome: 'bot' });
      return true;
    }
    if (input.viewerId) {
      const member = await db
        .selectFrom('bookings')
        .select('id')
        .where('plan_id', '=', invite.plan_id)
        .where('user_id', '=', input.viewerId)
        .where('status', '=', 'confirmed')
        .executeTakeFirst();
      if (member) {
        m.opens.add(1, { rail, outcome: 'member' });
        return true;
      }
    }
    const recorded = await db.transaction().execute(async (tx) => {
      const row = await tx
        .insertInto('invite_opens')
        .values({ invite_id: invite.id, device_id: input.deviceId })
        .onConflict((oc) => oc.columns(['invite_id', 'device_id']).doNothing())
        .returning('invite_id')
        .executeTakeFirst();
      if (!row) return false;
      await tx
        .insertInto('events')
        .values((eb) => ({
          name: 'invite_opened',
          user_id: input.viewerId,
          activity_id: invite.activity_id,
          invite_id: invite.id,
          rail,
          generation: input.viewerId
            ? eb.selectFrom('users').select('invite_generation').where('id', '=', input.viewerId)
            : null,
          platform: input.platform ?? null,
        }))
        .execute();
      await notifyPlan(tx, invite.plan_id);
      return true;
    });
    m.opens.add(1, { rail, outcome: recorded ? 'recorded' : 'duplicate' });
    if (recorded && rail === 'public') await maybeAutoPause(invite.id, invite.plan_id);
    return true;
  }

  /** PRD Operations, R7 (FR-019): the link's creator or the activity's host; public links only. */
  async function setPaused(input: { code: string; userId: string; paused: boolean }) {
    const invite = await loadByCode(input.code);
    if (!invite) throw new ApiError('not_found');
    const host = await db
      .selectFrom('activities')
      .select('host_id')
      .where('id', '=', invite.activity_id)
      .executeTakeFirstOrThrow();
    const reason: PauseReason | undefined =
      invite.inviter_id === input.userId ? 'owner' : host.host_id === input.userId ? 'host' : undefined;
    if (!reason) throw new ApiError('forbidden');
    if (invite.rail !== 'public') {
      throw new ApiError('validation_failed', 'Only public links can be paused.');
    }
    await db.transaction().execute(async (tx) => {
      const values = {
        paused: input.paused,
        paused_by: input.userId,
        paused_reason: input.paused ? reason : null,
      };
      await tx
        .insertInto('invite_controls')
        .values({ invite_id: invite.id, ...values })
        .onConflict((oc) => oc.column('invite_id').doUpdateSet({ ...values, updated_at: sql`now()` }))
        .execute();
      await notifyPlan(tx, invite.plan_id);
    });
  }

  return { loadByCode, create, view, open, setPaused };
}

export type InviteService = ReturnType<typeof createInviteService>;
export type LoadedInvite = NonNullable<Awaited<ReturnType<InviteService['loadByCode']>>>;
