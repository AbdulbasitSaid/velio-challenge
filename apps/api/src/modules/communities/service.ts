import type { ActivityCard } from '@velio/contracts';
import { sql } from 'kysely';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { buildCards } from '../activities/snapshot';
import { toPublicPerson } from '../identity/people';

/** At most this many activities on a community page [S4 proposal]. */
export const COMMUNITY_PAGE_LIMIT = 100;
/** "More in [community]" and the host's other dates (PRD Q9). */
export const NEXT_STEPS_LIMIT = 3;

const coverUrl = (key: string | null) => (key ? `/photos/${key}` : null);

export function createCommunityService(db: Db) {
  const upcomingCount = sql<number>`(SELECT count(*)::int FROM activities a
     WHERE a.community_id = communities.id AND a.starts_at > now())`;

  /** PRD Q11 (S4 FR-026). */
  async function list() {
    const rows = await db
      .selectFrom('communities')
      .select(['slug', 'name', 'blurb', 'cover_photo_key', upcomingCount.as('upcoming')])
      .orderBy('name')
      .execute();
    return {
      communities: rows.map((r) => ({
        slug: r.slug,
        name: r.name,
        blurb: r.blurb,
        coverPhotoUrl: coverUrl(r.cover_photo_key),
        upcomingCount: r.upcoming,
      })),
    };
  }

  /** PRD Q11, A6: every upcoming activity, sold-out ones included, soonest first. */
  async function page(slug: string) {
    const c = await db
      .selectFrom('communities')
      .select(['id', 'slug', 'name', 'blurb', 'cover_photo_key', upcomingCount.as('upcoming')])
      .where('slug', '=', slug)
      .executeTakeFirst();
    if (!c) throw new ApiError('not_found');
    const ids = await db
      .selectFrom('activities')
      .select('id')
      .where('community_id', '=', c.id)
      .where('starts_at', '>', sql<Date>`now()`)
      .orderBy('starts_at')
      .orderBy('id')
      .limit(COMMUNITY_PAGE_LIMIT)
      .execute();
    return {
      community: {
        slug: c.slug,
        name: c.name,
        blurb: c.blurb,
        coverPhotoUrl: coverUrl(c.cover_photo_key),
        upcomingCount: c.upcoming,
      },
      activities: await buildCards(
        db,
        ids.map((r) => r.id),
      ),
    };
  }

  /** PRD Q10 (S4 FR-027): never bookings or Plans. */
  async function profile(userId: string) {
    const user = await db
      .selectFrom('users')
      .select(['id', 'display_name', 'created_at'])
      .where('id', '=', userId)
      .executeTakeFirst();
    if (!user) throw new ApiError('not_found');
    const ids = await db
      .selectFrom('activities')
      .select('id')
      .where('host_id', '=', userId)
      .where('starts_at', '>', sql<Date>`now()`)
      .orderBy('starts_at')
      .execute();
    return {
      person: toPublicPerson(user),
      memberSince: user.created_at.toISOString().slice(0, 7),
      hosting: await buildCards(
        db,
        ids.map((r) => r.id),
      ),
    };
  }

  /** PRD Q9, Edge cases (S4 FR-028): what a sold-out or expired screen offers instead. */
  async function nextSteps(
    activityId: string,
  ): Promise<{ hostOtherDates: ActivityCard[]; moreInCommunity: ActivityCard[] }> {
    const a = await db
      .selectFrom('activities')
      .select(['host_id', 'community_id'])
      .where('id', '=', activityId)
      .executeTakeFirst();
    if (!a) throw new ApiError('not_found');
    const withSpots = () =>
      db
        .selectFrom('activities')
        .select('id')
        .where('id', '<>', activityId)
        .where('starts_at', '>', sql<Date>`now()`)
        .where('spots_left', '>', 0)
        .orderBy('starts_at')
        .orderBy('id')
        .limit(NEXT_STEPS_LIMIT);
    const host = await withSpots().where('host_id', '=', a.host_id).execute();
    const more = await withSpots().where('community_id', '=', a.community_id).execute();
    const cards = new Map(
      (await buildCards(db, [...new Set([...host, ...more].map((r) => r.id))])).map((c) => [c.id, c]),
    );
    return {
      hostOtherDates: host.map((r) => cards.get(r.id)!),
      moreInCommunity: more.map((r) => cards.get(r.id)!),
    };
  }

  return { list, page, profile, nextSteps };
}

export type CommunityService = ReturnType<typeof createCommunityService>;
