import { metrics, type MeterProvider } from '@opentelemetry/api';
import { sql } from 'kysely';
import type { Db } from '../db/client';
import type { Logger } from '../telemetry/logger';

const FIVE_MINUTES_MS = 5 * 60_000;
const DAY_MS = 86_400_000;
/** Engineering choice (S8 PLANNING §11): the nightly audit runs at 02:00 UTC. */
const AUDIT_HOUR_UTC = 2;

/** Advisory lock keys: a second API instance skips a job the first is running. */
const LOCKS = { oversell: 8_001, audit: 8_002 } as const;

export interface AuditResult {
  ranAt: Date;
  failures: { activityId: string; table: string; firstBadSeq: number }[];
}

/** Milliseconds from `now` to the next 02:00 UTC. */
export function untilNextAudit(now: Date): number {
  const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), AUDIT_HOUR_UTC));
  if (next.getTime() <= now.getTime()) next.setUTCDate(next.getUTCDate() + 1);
  return next.getTime() - now.getTime();
}

/**
 * PRD Operations (S8 FR-015, FR-016): the oversell check every 5 minutes and the nightly attribution
 * audit, run in the API process. Each feeds a gauge that Grafana alerts on.
 */
export function createJobs(deps: { db: Db; logger: Logger; meterProvider?: MeterProvider }) {
  const { db, logger } = deps;
  let oversell: number | undefined;
  let lastAudit: AuditResult | undefined;
  const timers: ReturnType<typeof setTimeout>[] = [];

  const meter = (deps.meterProvider ?? metrics.getMeterProvider()).getMeter('velio-jobs');
  meter
    .createObservableGauge('oversell_activities', {
      description: 'Activities whose confirmed bookings exceed capacity, from the 5-minute check. Must be 0',
    })
    .addCallback((r) => {
      if (oversell !== undefined) r.observe(oversell);
    });
  meter
    .createObservableGauge('audit_chain_failures', {
      description: 'Hash chains that failed the last attribution audit. Must be 0',
    })
    .addCallback((r) => {
      if (lastAudit) r.observe(lastAudit.failures.length);
    });

  /** Runs `fn` holding a session advisory lock, or returns undefined if another process holds it. */
  async function locked<T>(key: number, fn: (conn: Db) => Promise<T>): Promise<T | undefined> {
    return db.connection().execute(async (conn) => {
      const { rows } = await sql<{ ok: boolean }>`SELECT pg_try_advisory_lock(${key}) AS ok`.execute(conn);
      if (!rows[0]?.ok) return undefined;
      try {
        return await fn(conn);
      } finally {
        await sql`SELECT pg_advisory_unlock(${key})`.execute(conn);
      }
    });
  }

  async function checkOversell(): Promise<number | undefined> {
    const count = await locked(LOCKS.oversell, async (conn) => {
      const row = await conn
        .selectFrom('v_oversell')
        .select((eb) => eb.fn.countAll<string>().as('n'))
        .executeTakeFirstOrThrow();
      return Number(row.n);
    });
    if (count === undefined) return oversell;
    oversell = count;
    // The count only: activity IDs stay out of logs that leave the host (CLAUDE.md telemetry rule).
    if (count > 0) logger.error({ count }, 'oversell_detected');
    return count;
  }

  async function audit(): Promise<AuditResult> {
    const result = await locked(LOCKS.audit, async (conn) => {
      const { rows } = await sql<{ activity_id: string; table_name: string; first_bad_seq: string }>`
        SELECT activity_id, table_name, first_bad_seq FROM audit_all_chains()`.execute(conn);
      return {
        ranAt: new Date(),
        failures: rows.map((r) => ({
          activityId: r.activity_id,
          table: r.table_name,
          firstBadSeq: Number(r.first_bad_seq),
        })),
      };
    });
    if (!result) return lastAudit ?? { ranAt: new Date(), failures: [] };
    lastAudit = result;
    if (result.failures.length > 0)
      logger.error({ count: result.failures.length }, 'attribution_audit_failed');
    else logger.info('attribution_audit_ok');
    return result;
  }

  /** A failed run is logged and retried at the next tick; the gauge keeps its last value. */
  const safely = (name: string, fn: () => Promise<unknown>) => () =>
    void fn().catch((err: unknown) => logger.warn({ err, job: name }, 'job failed'));

  return {
    checkOversell,
    audit,
    lastAudit: () => lastAudit,
    start(now: () => Date = () => new Date()) {
      const oversellTick = safely('oversell', checkOversell);
      const auditTick = safely('audit', audit);
      oversellTick();
      timers.push(setInterval(oversellTick, FIVE_MINUTES_MS));
      timers.push(
        setTimeout(() => {
          auditTick();
          timers.push(setInterval(auditTick, DAY_MS));
        }, untilNextAudit(now())),
      );
    },
    stop() {
      for (const t of timers) clearTimeout(t);
      timers.length = 0;
    },
  };
}

export type Jobs = ReturnType<typeof createJobs>;
