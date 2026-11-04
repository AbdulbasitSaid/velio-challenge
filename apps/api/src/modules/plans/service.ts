import type { MemberPerson, MyPlans, PlanView } from '@velio/contracts';
import { sql } from 'kysely';
import type { Config } from '../../config';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { buildCards, MEMBER_PREVIEW } from '../activities/snapshot';
import { toMemberPerson } from '../identity/people';
import { inviteLink } from '../invites/codes';
import { inviteStats, planInviteStatus } from '../invites/service';

type Status = 'confirmed' | 'removed';
type Source = 'direct' | 'vouch' | 'public';

const person = (id: string | null, name: string | null): MemberPerson | null =>
  id && name ? toMemberPerson({ id, display_name: name }) : null;

export function createPlanService(db: Db, config: Config) {
  /**
   * PRD L1, Q12, D5 (S4 FR-020): for anyone with a booking in the Plan. Full names, because the
   * reader is a member; codes, links and notes only on the reader's own invites.
   */
  async function view(planId: string, viewerId: string): Promise<PlanView> {
    const plan = await db
      .selectFrom('plans as p')
      .innerJoin('activities as a', 'a.id', 'p.activity_id')
      .innerJoin('users as o', 'o.id', 'p.owner_id')
      .select([
        'p.id',
        'a.id as activity_id',
        'a.title',
        'a.starts_at',
        'a.timezone',
        sql<boolean>`a.starts_at <= now()`.as('started'),
        'o.id as owner_id',
        'o.display_name as owner_name',
      ])
      .where('p.id', '=', planId)
      .executeTakeFirst();
    if (!plan) throw new ApiError('not_found');
    const own = await db
      .selectFrom('bookings')
      .select(['id', 'ref', 'status'])
      .where('plan_id', '=', planId)
      .where('user_id', '=', viewerId)
      .executeTakeFirst();
    if (!own) throw new ApiError('forbidden');
    const confirmed = own.status === 'confirmed';

    const members = await db
      .selectFrom('bookings as b')
      .innerJoin('users as u', 'u.id', 'b.user_id')
      .leftJoin('invites as i', 'i.id', 'b.invite_id')
      .leftJoin('users as inv', 'inv.id', 'i.inviter_id')
      .select([
        'u.id',
        'u.display_name',
        'b.source',
        'b.created_at',
        'inv.id as inviter_id',
        'inv.display_name as inviter_name',
      ])
      .where('b.plan_id', '=', planId)
      .where('b.status', '=', 'confirmed')
      .orderBy('b.created_at')
      .orderBy('b.id')
      .execute();

    const invites = confirmed
      ? await db
          .selectFrom('invites as i')
          .innerJoin('users as u', 'u.id', 'i.inviter_id')
          .select([
            'i.id',
            'i.code',
            'i.rail',
            'i.invitee_name',
            'i.note',
            'i.created_at',
            'u.id as creator_id',
            'u.display_name as creator_name',
          ])
          .where('i.plan_id', '=', planId)
          .orderBy('i.created_at')
          .orderBy('i.id')
          .execute()
      : [];
    const stats = await inviteStats(
      db,
      invites.map((i) => i.id),
    );

    return {
      id: plan.id,
      activity: {
        id: plan.activity_id,
        title: plan.title,
        startsAt: plan.starts_at.toISOString(),
        timezone: plan.timezone,
      },
      owner: toMemberPerson({ id: plan.owner_id, display_name: plan.owner_name }),
      members: members.map((m) => ({
        person: toMemberPerson(m),
        source: m.source as Source,
        invitedBy: person(m.inviter_id, m.inviter_name),
        joinedAt: m.created_at.toISOString(),
      })),
      viewer: {
        booking: { id: own.id, ref: own.ref, status: own.status as Status },
        canInvite: confirmed && !plan.started,
      },
      invites: invites.map((i) => {
        const s = stats.get(i.id)!;
        const mine = i.creator_id === viewerId;
        return {
          id: i.id,
          rail: i.rail as 'vouch' | 'public',
          inviteeName: i.invitee_name,
          createdBy: toMemberPerson({ id: i.creator_id, display_name: i.creator_name }),
          status: planInviteStatus(i.rail as 'vouch' | 'public', s, plan.started),
          ...s,
          createdAt: i.created_at.toISOString(),
          ...(mine && { code: i.code, link: inviteLink(config.PUBLIC_BASE_URL, i.code), note: i.note }),
        };
      }),
    };
  }

  /** PRD L2, Q14 (S4 FR-022): every Plan the caller has a booking in, in a fixed number of queries. */
  async function mine(userId: string): Promise<MyPlans> {
    const rows = await db
      .selectFrom('bookings as b')
      .innerJoin('activities as a', 'a.id', 'b.activity_id')
      .select([
        'b.id',
        'b.ref',
        'b.status',
        'b.plan_id',
        'b.activity_id',
        'a.starts_at',
        sql<boolean>`a.starts_at <= now()`.as('past'),
      ])
      .where('b.user_id', '=', userId)
      .orderBy('a.starts_at')
      .execute();
    const cards = new Map(
      (
        await buildCards(
          db,
          rows.map((r) => r.activity_id),
        )
      ).map((c) => [c.id, c]),
    );
    const planIds = rows.map((r) => r.plan_id);
    const members =
      planIds.length === 0
        ? []
        : await db
            .selectFrom((eb) =>
              eb
                .selectFrom('bookings as b')
                .innerJoin('users as u', 'u.id', 'b.user_id')
                .select([
                  'b.plan_id',
                  'u.id',
                  'u.display_name',
                  sql<number>`row_number() OVER (PARTITION BY b.plan_id ORDER BY b.created_at, b.id)::int`.as(
                    'n',
                  ),
                  sql<number>`count(*) OVER (PARTITION BY b.plan_id)::int`.as('total'),
                ])
                .where('b.plan_id', 'in', planIds)
                .where('b.status', '=', 'confirmed')
                .as('m'),
            )
            .selectAll()
            .where('m.n', '<=', MEMBER_PREVIEW)
            .orderBy('m.n')
            .execute();
    const byPlan = new Map<string, { count: number; preview: MemberPerson[] }>();
    for (const m of members) {
      const entry = byPlan.get(m.plan_id) ?? { count: m.total, preview: [] };
      entry.preview.push(toMemberPerson(m));
      byPlan.set(m.plan_id, entry);
    }
    const toPlan = (r: (typeof rows)[number]) => ({
      planId: r.plan_id,
      activity: cards.get(r.activity_id)!,
      booking: { id: r.id, ref: r.ref, status: r.status as Status },
      members: byPlan.get(r.plan_id) ?? { count: 0, preview: [] },
    });
    return {
      upcoming: rows.filter((r) => !r.past).map(toPlan),
      past: rows
        .filter((r) => r.past)
        .reverse()
        .map(toPlan),
    };
  }

  return { view, mine };
}

export type PlanService = ReturnType<typeof createPlanService>;
