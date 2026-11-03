import { randomBytes } from 'node:crypto';
import type postgres from 'postgres';

const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

function randomFrom(alphabet: string, length: number): string {
  return Array.from(randomBytes(length), (b) => alphabet[b % alphabet.length]).join('');
}

export const inviteCode = () => randomFrom(ALPHABET, 6);
export const bookingRef = () => `VLO-${randomFrom(ALPHABET, 5)}`;

export async function insertUser(sql: postgres.Sql, displayName = 'Tunde Adeyemi', generation = 0) {
  const [row] = await sql<{ id: string }[]>`
    INSERT INTO users (display_name, contact_hash, invite_generation)
    VALUES (${displayName}, ${randomBytes(32)}, ${generation})
    RETURNING id`;
  return row!.id;
}

export const validActivity = {
  title: 'Sunset Kayaking',
  starts_at: new Date(Date.now() + 30 * 86_400_000),
  timezone: 'Africa/Nairobi',
  place_id: 'ChIJ_example',
  venue_name: 'Lake Naivasha Boat Club',
  address_text: 'Moi South Lake Rd, Naivasha, Kenya',
  lat: '-0.766700',
  lng: '36.433300',
  meeting_point: 'Meet at the blue gate by the jetty',
  price_minor: 350000,
  currency: 'KES',
  capacity: 14,
  spots_left: 14,
};

export type ActivityInput = Partial<Record<keyof typeof validActivity, unknown>>;

export async function insertActivity(sql: postgres.Sql, hostId: string, overrides: ActivityInput = {}) {
  const [community] = await sql<{ id: string }[]>`SELECT id FROM communities WHERE slug = 'explore-kenya'`;
  const values = { ...validActivity, ...overrides, host_id: hostId, community_id: community!.id };
  const [row] = await sql<
    { id: string }[]
  >`INSERT INTO activities ${sql(values as Record<string, postgres.ParameterOrJSON<never>>)} RETURNING id`;
  return row!.id;
}

export async function insertPlan(sql: postgres.Sql, activityId: string, ownerId: string) {
  const [row] = await sql<{ id: string }[]>`
    INSERT INTO plans (activity_id, owner_id) VALUES (${activityId}, ${ownerId}) RETURNING id`;
  return row!.id;
}

export async function insertBooking(
  sql: postgres.Sql,
  b: {
    activityId: string;
    userId: string;
    planId: string;
    source?: 'direct' | 'vouch' | 'public';
    inviteId?: string | null;
    status?: 'confirmed' | 'removed';
    ref?: string;
  },
) {
  const [row] = await sql<{ id: string }[]>`
    INSERT INTO bookings (ref, activity_id, user_id, plan_id, source, invite_id, idempotency_key, status)
    VALUES (${b.ref ?? bookingRef()}, ${b.activityId}, ${b.userId}, ${b.planId}, ${b.source ?? 'direct'},
            ${b.inviteId ?? null}, ${randomBytes(8).toString('hex')}, ${b.status ?? 'confirmed'})
    RETURNING id`;
  return row!.id;
}

export async function insertInvite(
  sql: postgres.Sql,
  i: { activityId: string; planId: string; inviterId: string; rail?: 'vouch' | 'public' },
) {
  const [row] = await sql<{ id: string }[]>`
    INSERT INTO invites (code, rail, activity_id, plan_id, inviter_id)
    VALUES (${inviteCode()}, ${i.rail ?? 'vouch'}, ${i.activityId}, ${i.planId}, ${i.inviterId})
    RETURNING id`;
  return row!.id;
}

/** One row in every insert-only table, so row-level triggers have something to fire on. */
export async function seedInsertOnlyRows(sql: postgres.Sql) {
  const host = await insertUser(sql, 'Amara Okafor');
  const booker = await insertUser(sql, 'Tunde Adeyemi');
  const guest = await insertUser(sql, 'Zainab Bello', 1);
  const activity = await insertActivity(sql, host);
  const plan = await insertPlan(sql, activity, booker);
  const invite = await insertInvite(sql, { activityId: activity, planId: plan, inviterId: booker });
  const booking = await insertBooking(sql, {
    activityId: activity,
    userId: guest,
    planId: plan,
    source: 'vouch',
    inviteId: invite,
  });
  await sql`INSERT INTO invite_claims (booking_id, invite_id, rail) VALUES (${booking}, ${invite}, 'vouch')`;
  await sql`
    INSERT INTO attributions (invitee_id, inviter_id, invite_id, rail, generation)
    VALUES (${guest}, ${booker}, ${invite}, 'vouch', 1)`;
  await sql`INSERT INTO trust_edges (voucher_id, vouchee_id, invite_id) VALUES (${booker}, ${guest}, ${invite})`;
  await sql`INSERT INTO attendance_marks (booking_id, mark, marked_by) VALUES (${booking}, 'attended', ${host})`;
  await sql`INSERT INTO booking_removals (booking_id, removed_by) VALUES (${booking}, ${host})`;
  return { host, booker, guest, activity, plan, invite, booking };
}
