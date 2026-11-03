import { SpanStatusCode, trace } from '@opentelemetry/api';
import type { ActivityState, Booking } from '@velio/contracts';
import { sql, type Selectable, type Transaction } from 'kysely';
import type { Db } from '../../db/client';
import type { Bookings, DB } from '../../db/types';
import { ApiError } from '../../errors';
import type { Logger } from '../../telemetry/logger';
import type { BookingMetrics, BookingPath } from './metrics';
import { newBookingRef } from './ref';

// The only module that writes activities.spots_left (MVP plan §6). Every write path locks the
// activity row before touching bookings, so booking, removal and capacity edits can't deadlock.

export type Tx = Transaction<DB>;
export type BookingRow = Selectable<Bookings>;
export type BookingSource = 'direct' | 'vouch' | 'public';

export interface BookSpotInput {
  activityId: string;
  userId: string;
  idempotencyKey: string;
  source: BookingSource;
  /** Claims join the inviter's Plan (S4). Direct bookings create a new one. */
  planId?: string;
  inviteId?: string;
  platform?: string;
  /** Runs inside the booking transaction after the booking row exists (S4: claim and attribution rows). */
  extend?: (tx: Tx, booking: BookingRow) => Promise<void>;
}

export interface BookingResult {
  /** False for an idempotent replay. */
  created: boolean;
  booking: BookingRow;
  activity: ActivityState;
}

export interface RemovalResult {
  /** False when the booking was already removed: nothing was freed. */
  removed: boolean;
  booking: BookingRow;
  activity: ActivityState;
}

const REF_ATTEMPTS = 5;

/** Rejections that record a `booking_rejected` event. Replays and key conflicts record nothing. */
const REJECTIONS = new Set([
  'not_found',
  'forbidden',
  'already_booked',
  'booking_removed',
  'activity_started',
  'bookings_paused',
  'sold_out',
]);

/** The conditional UPDATE matched no row; thrown inside the transaction to roll it back. */
class SpotUnavailable extends Error {}

/** The constraint behind a unique violation, if `err` is one. */
function uniqueViolation(err: unknown): string | undefined {
  const e = err as { code?: unknown; constraint_name?: unknown } | null;
  return e?.code === '23505' && typeof e.constraint_name === 'string' ? e.constraint_name : undefined;
}

export function toBooking(row: BookingRow): Booking {
  return {
    id: row.id,
    ref: row.ref,
    activityId: row.activity_id,
    planId: row.plan_id,
    source: row.source as Booking['source'],
    status: row.status as Booking['status'],
    createdAt: row.created_at.toISOString(),
  };
}

/** Delivered by Postgres only on commit. S3 listens; `committedAt` is its latency reference. */
async function notifySpots(tx: Tx, state: ActivityState) {
  await sql`
    SELECT pg_notify('activity_spots', json_build_object(
      'activityId', ${state.id}::uuid,
      'spotsLeft', ${state.spotsLeft}::int,
      'version', ${state.version}::bigint,
      'committedAt', clock_timestamp())::text)`.execute(tx);
}

/**
 * Sets capacity, moving spots_left by the same difference (PRD business rules, Capacity). Never
 * below confirmed bookings. Setting the current value changes nothing and keeps `version`.
 */
export async function changeCapacity(tx: Tx, activityId: string, capacity: number): Promise<ActivityState> {
  const changed = await tx
    .updateTable('activities')
    .set(() => ({
      capacity,
      spots_left: sql<number>`spots_left + (${capacity}::int - capacity)`,
      version: sql<string>`version + 1`,
    }))
    .where('id', '=', activityId)
    .where(sql<number>`capacity - spots_left`, '<=', capacity)
    .where('capacity', '<>', capacity)
    .returning(['spots_left', 'version'])
    .executeTakeFirst();
  if (changed) {
    const state = { id: activityId, spotsLeft: changed.spots_left, version: Number(changed.version) };
    await notifySpots(tx, state);
    return state;
  }
  const row = await tx
    .selectFrom('activities')
    .select(['capacity', 'spots_left', 'version'])
    .where('id', '=', activityId)
    .executeTakeFirstOrThrow();
  if (row.capacity !== capacity) throw new ApiError('capacity_below_bookings');
  return { id: activityId, spotsLeft: row.spots_left, version: Number(row.version) };
}

export interface BookingEngineDeps {
  db: Db;
  logger: Logger;
  metrics: BookingMetrics;
  /** Injected by tests to force reference collisions. */
  newRef?: () => string;
}

export function createBookingEngine(deps: BookingEngineDeps) {
  const { db, logger, metrics: m } = deps;
  const newRef = deps.newRef ?? newBookingRef;
  const tracer = trace.getTracer('velio-bookings');

  async function currentState(activityId: string): Promise<ActivityState> {
    const row = await db
      .selectFrom('activities')
      .select(['spots_left', 'version'])
      .where('id', '=', activityId)
      .executeTakeFirstOrThrow();
    return { id: activityId, spotsLeft: row.spots_left, version: Number(row.version) };
  }

  /** The booking this user already made with this key, whatever its status now. */
  async function findReplay(input: BookSpotInput): Promise<BookingResult | undefined> {
    const existing = await db
      .selectFrom('bookings')
      .selectAll()
      .where('user_id', '=', input.userId)
      .where('idempotency_key', '=', input.idempotencyKey)
      .executeTakeFirst();
    if (!existing) return undefined;
    if (existing.activity_id !== input.activityId) throw new ApiError('idempotency_conflict');
    return { created: false, booking: existing, activity: await currentState(existing.activity_id) };
  }

  /** Read checks for clear errors, in the FR-003 order. The transaction stays the authority. */
  async function precheck(input: BookSpotInput) {
    const activity = await db
      .selectFrom('activities')
      .select('host_id')
      .where('id', '=', input.activityId)
      .executeTakeFirst();
    if (!activity) throw new ApiError('not_found');
    if (activity.host_id === input.userId)
      throw new ApiError('forbidden', 'Hosts cannot book their own activity.');
    const previous = await db
      .selectFrom('bookings')
      .select('status')
      .where('activity_id', '=', input.activityId)
      .where('user_id', '=', input.userId)
      .execute();
    if (previous.some((b) => b.status === 'confirmed')) throw new ApiError('already_booked');
    if (previous.some((b) => b.status === 'removed')) throw new ApiError('booking_removed');
  }

  /** Why the conditional UPDATE matched nothing, in the order started → paused → sold out. */
  async function unavailableReason(activityId: string): Promise<ApiError> {
    const row = await db
      .selectFrom('activities')
      .select([sql<boolean>`starts_at <= now()`.as('started'), 'bookings_paused'])
      .where('id', '=', activityId)
      .executeTakeFirstOrThrow();
    if (row.started) return new ApiError('activity_started');
    if (row.bookings_paused) return new ApiError('bookings_paused');
    return new ApiError('sold_out');
  }

  function transact(input: BookSpotInput): Promise<BookingResult> {
    return db.transaction().execute(async (tx) => {
      // Takes the spot and the activity row lock. A waiting UPDATE re-checks its WHERE against the
      // committed row (READ COMMITTED), so the last spot can be taken only once.
      const waitStart = performance.now();
      const taken = await tx
        .updateTable('activities')
        .set((eb) => ({ spots_left: eb('spots_left', '-', 1), version: sql<string>`version + 1` }))
        .where('id', '=', input.activityId)
        .where('spots_left', '>', 0)
        .where('starts_at', '>', sql<Date>`now()`)
        .where('bookings_paused', '=', false)
        .returning(['spots_left', 'version'])
        .executeTakeFirst();
      m.rowWait.record((performance.now() - waitStart) / 1000);
      if (!taken) throw new SpotUnavailable();

      const planId =
        input.planId ??
        (
          await tx
            .insertInto('plans')
            .values({ activity_id: input.activityId, owner_id: input.userId })
            .returning('id')
            .executeTakeFirstOrThrow()
        ).id;

      // ON CONFLICT (ref) suppresses only reference collisions; the other unique constraints raise.
      let booking: BookingRow | undefined;
      for (let attempt = 0; !booking && attempt < REF_ATTEMPTS; attempt++) {
        booking = await tx
          .insertInto('bookings')
          .values({
            ref: newRef(),
            activity_id: input.activityId,
            user_id: input.userId,
            plan_id: planId,
            source: input.source,
            invite_id: input.inviteId ?? null,
            idempotency_key: input.idempotencyKey,
          })
          .onConflict((oc) => oc.column('ref').doNothing())
          .returningAll()
          .executeTakeFirst();
      }
      if (!booking) throw new Error(`booking reference collided ${REF_ATTEMPTS} times`);

      await input.extend?.(tx, booking);

      await tx
        .insertInto('events')
        .values((eb) => ({
          name: 'booking_succeeded',
          user_id: input.userId,
          activity_id: input.activityId,
          invite_id: input.inviteId ?? null,
          rail: input.source === 'direct' ? null : input.source,
          generation: eb.selectFrom('users').select('invite_generation').where('id', '=', input.userId),
          platform: input.platform ?? null,
        }))
        .execute();

      const activity = { id: input.activityId, spotsLeft: taken.spots_left, version: Number(taken.version) };
      await notifySpots(tx, activity);
      return { created: true, booking, activity };
    });
  }

  async function attempt(input: BookSpotInput): Promise<BookingResult> {
    const replay = await findReplay(input);
    if (replay) return replay;
    try {
      await precheck(input);
      return await transact(input);
    } catch (err) {
      // A parallel request with the same key may have committed since the first lookup, making
      // this one look already booked, sold out or a unique violation. It's a replay of that one.
      const winner = await findReplay(input);
      if (winner) return winner;
      if (err instanceof SpotUnavailable) throw await unavailableReason(input.activityId);
      // A parallel request with another key won; this transaction rolled back, returning its spot.
      if (uniqueViolation(err) === 'bookings_one_confirmed_per_user') throw new ApiError('already_booked');
      throw err;
    }
  }

  /** Best-effort: a failure is logged and never changes the response. */
  async function recordRejection(input: BookSpotInput, reason: string) {
    try {
      await db
        .insertInto('events')
        .values({
          name: 'booking_rejected',
          user_id: input.userId,
          // events.activity_id references activities, so an unknown ID can't be stored.
          activity_id: reason === 'not_found' ? null : input.activityId,
          invite_id: input.inviteId ?? null,
          platform: input.platform ?? null,
          props: sql`jsonb_build_object('reason', ${reason}::text)`,
        })
        .execute();
    } catch (err) {
      logger.warn({ err, activity_id: input.activityId }, 'booking_rejected event not recorded');
    }
  }

  /**
   * Confirmed bookings must equal capacity − spots_left (PRD Operations). One statement, so both
   * sides come from one snapshot and a concurrent booking can't raise a false alarm.
   */
  async function assertNoOversell(activityId: string) {
    try {
      const { rows } = await sql<{ taken: number; confirmed: number }>`
        SELECT a.capacity - a.spots_left AS taken,
               (SELECT count(*)::int FROM bookings b
                 WHERE b.activity_id = a.id AND b.status = 'confirmed') AS confirmed
          FROM activities a
         WHERE a.id = ${activityId}`.execute(db);
      const row = rows[0];
      if (row && row.taken !== row.confirmed) {
        m.oversell.add(1);
        logger.error({ activity_id: activityId }, 'oversell_detected');
      }
    } catch (err) {
      logger.warn({ err, activity_id: activityId }, 'oversell check failed');
    }
  }

  /**
   * Books one spot or throws a typed ApiError, never both (PRD B1). A repeat with the same user and
   * Idempotency-Key returns the original booking with `created: false` (PRD B2).
   */
  function bookSpot(input: BookSpotInput): Promise<BookingResult> {
    const path: BookingPath = input.source === 'direct' ? 'direct' : 'claim';
    const start = performance.now();
    return tracer.startActiveSpan(
      'booking.transaction',
      { attributes: { 'activity.id': input.activityId, 'booking.path': path } },
      async (span) => {
        let outcome = 'error';
        try {
          const result = await attempt(input);
          outcome = result.created ? 'success' : 'replay';
          if (result.created) await assertNoOversell(input.activityId);
          return result;
        } catch (err) {
          if (err instanceof ApiError && err.code !== 'internal') {
            outcome = err.code;
            if (REJECTIONS.has(err.code)) await recordRejection(input, err.code);
          } else {
            span.setStatus({ code: SpanStatusCode.ERROR });
          }
          throw err;
        } finally {
          const attrs = { outcome, path };
          span.setAttribute('booking.outcome', outcome);
          span.end();
          m.attempts.add(1, attrs);
          m.duration.record((performance.now() - start) / 1000, attrs);
        }
      },
    );
  }

  /**
   * Host removal (PRD H1, D3): the booking becomes `removed` and its spot is free for whoever books
   * next. Repeating it frees nothing more.
   */
  async function removeBooking(input: { bookingId: string; hostId: string }): Promise<RemovalResult> {
    const found = await db
      .selectFrom('bookings')
      .select('activity_id')
      .where('id', '=', input.bookingId)
      .executeTakeFirst();
    if (!found) throw new ApiError('not_found');
    const activityId = found.activity_id;

    const result = await db.transaction().execute(async (tx): Promise<RemovalResult> => {
      // Lock the activity row first (lock order), and check the host in the same transaction.
      const activity = await tx
        .selectFrom('activities')
        .select(['host_id', 'spots_left', 'version'])
        .where('id', '=', activityId)
        .forUpdate()
        .executeTakeFirstOrThrow();
      if (activity.host_id !== input.hostId) throw new ApiError('forbidden');

      const removed = await tx
        .updateTable('bookings')
        .set({ status: 'removed' })
        .where('id', '=', input.bookingId)
        .where('status', '=', 'confirmed')
        .returningAll()
        .executeTakeFirst();
      if (!removed) {
        const booking = await tx
          .selectFrom('bookings')
          .selectAll()
          .where('id', '=', input.bookingId)
          .executeTakeFirstOrThrow();
        const state = { id: activityId, spotsLeft: activity.spots_left, version: Number(activity.version) };
        return { removed: false, booking, activity: state };
      }

      const freed = await tx
        .updateTable('activities')
        .set((eb) => ({ spots_left: eb('spots_left', '+', 1), version: sql<string>`version + 1` }))
        .where('id', '=', activityId)
        .returning(['spots_left', 'version'])
        .executeTakeFirstOrThrow();
      await tx
        .insertInto('booking_removals')
        .values({ booking_id: input.bookingId, removed_by: input.hostId })
        .execute();
      const state = { id: activityId, spotsLeft: freed.spots_left, version: Number(freed.version) };
      await notifySpots(tx, state);
      return { removed: true, booking: removed, activity: state };
    });

    m.removals.add(1, { outcome: result.removed ? 'removed' : 'already_removed' });
    return result;
  }

  return { bookSpot, removeBooking };
}

export type BookingEngine = ReturnType<typeof createBookingEngine>;
