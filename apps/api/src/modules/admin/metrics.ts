import type { AdminGoal, AdminMetrics, Ratio } from '@velio/contracts';
import { sql } from 'kysely';
import type { Db } from '../../db/client';
import type { RollingWindow } from '../../telemetry/rolling';
import type { AuditResult } from '../../jobs/jobs';

/** PRD "Success metrics and tracking": targets and triggers, as written there. */
export const TARGETS = {
  bookingSuccess: 0.995,
  realtimeP95Seconds: 2,
  inviteRate: 0.3,
  inviteRateTrigger: 0.25,
  vouchOpenToClaim: 0.25,
  vouchOpenToClaimTrigger: 0.2,
  guardrailRatio: 1.5,
} as const;

export function ratio(numerator: number, denominator: number): Ratio {
  return { numerator, denominator, value: denominator > 0 ? numerator / denominator : null };
}

type Rail = 'vouch' | 'public';
const RAILS: Rail[] = ['vouch', 'public'];

/** S8 FR-009: every PRD goal and metric over the last `days`, from the S8 views. */
export async function adminMetrics(
  db: Db,
  input: { days: number; latency?: RollingWindow; audit?: AuditResult },
): Promise<AdminMetrics> {
  const since = sql<Date>`now() - make_interval(days => ${input.days})`;
  const n = (v: unknown) => Number(v ?? 0);

  const [oversell, success, lastHour, inviteRate, funnel, kFactor, plans, guardrail, holdout, holdoutPlans] =
    await Promise.all([
      sql<{ n: string }>`SELECT count(*) AS n FROM v_oversell`.execute(db),
      sql<{ success: string; total: string }>`
        SELECT count(*) FILTER (WHERE outcome = 'success') AS success, count(*) AS total
          FROM v_booking_success WHERE at >= ${since}`.execute(db),
      sql<{ success: string; total: string }>`
        SELECT count(*) FILTER (WHERE outcome = 'success') AS success, count(*) AS total
          FROM v_booking_success WHERE at >= now() - interval '1 hour'`.execute(db),
      sql<{ bookers: string; any: string; vouch: string; public: string }>`
        SELECT count(*) AS bookers,
               count(*) FILTER (WHERE invited_vouch OR invited_public) AS any,
               count(*) FILTER (WHERE invited_vouch) AS vouch,
               count(*) FILTER (WHERE invited_public) AS public
          FROM v_invite_rate WHERE arm = 'exposed' AND first_booked_at >= ${since}`.execute(db),
      sql<{ rail: Rail; invites: string; opens: string; claims: string }>`
        SELECT rail, count(*) AS invites, sum(opens) AS opens, sum(claims) AS claims
          FROM v_open_to_claim_by_rail WHERE created_at >= ${since} GROUP BY rail`.execute(db),
      sql<{ rail: Rail; new_users: string; inviters: string }>`
        SELECT rail, sum(new_users) AS new_users, count(DISTINCT inviter_id) AS inviters
          FROM v_k_factor_by_rail WHERE created_at >= ${since} GROUP BY rail`.execute(db),
      sql<{ happened: string; reached: string }>`
        SELECT count(*) FILTER (WHERE happened) AS happened, count(*) AS reached
          FROM v_plans_happened WHERE starts_at >= ${since}`.execute(db),
      sql<{ invited: boolean; bad: string; total: string }>`
        SELECT invited, count(*) FILTER (WHERE bad) AS bad, count(*) AS total
          FROM v_guardrail WHERE starts_at >= ${since} GROUP BY invited`.execute(db),
      sql<{ arm: 'exposed' | 'holdout'; users: string; bookers: string; new_users: string }>`
        SELECT arm, count(*) AS users, count(*) FILTER (WHERE booked) AS bookers,
               coalesce(sum(new_users) FILTER (WHERE booked), 0) AS new_users
          FROM v_holdout WHERE first_exposed_at >= ${since} GROUP BY arm`.execute(db),
      sql<{ arm: 'exposed' | 'holdout'; happened: string; reached: string }>`
        SELECT arm, count(*) FILTER (WHERE happened) AS happened, count(*) AS reached
          FROM v_plans_happened WHERE arm IS NOT NULL AND starts_at >= ${since} GROUP BY arm`.execute(db),
    ]);

  const oversellCount = n(oversell.rows[0]?.n);
  const successRatio = ratio(n(success.rows[0]?.success), n(success.rows[0]?.total));
  const hourRatio = ratio(n(lastHour.rows[0]?.success), n(lastHour.rows[0]?.total));
  const ir = inviteRate.rows[0];
  const bookers = n(ir?.bookers);
  const byRail = <T extends { rail: Rail }>(rows: T[], rail: Rail) => rows.find((r) => r.rail === rail);
  const funnelRows = RAILS.map((rail) => {
    const r = byRail(funnel.rows, rail);
    const opens = n(r?.opens);
    const claims = n(r?.claims);
    return { rail, invites: n(r?.invites), opens, claims, openToClaim: ratio(claims, opens) };
  });
  const vouch = funnelRows[0]!.openToClaim;
  const pub = funnelRows[1]!.openToClaim;
  const invitedG = guardrail.rows.find((r) => r.invited);
  const organicG = guardrail.rows.find((r) => !r.invited);
  const invited = ratio(n(invitedG?.bad), n(invitedG?.total));
  const organic = ratio(n(organicG?.bad), n(organicG?.total));
  const guardRatio = invited.value !== null && organic.value ? invited.value / organic.value : null;
  const p95 = input.latency?.quantile(0.95) ?? { value: null, count: 0 };
  const inviteAny = ratio(n(ir?.any), bookers);

  const goals: AdminGoal[] = [
    {
      id: 'no_oversell',
      label: 'Never oversell',
      unit: 'count',
      value: oversellCount,
      target: 0,
      trigger: 'Any single occurrence',
      triggered: oversellCount > 0,
      sample: oversellCount,
    },
    {
      id: 'booking_success',
      label: 'Bookings succeed when spots exist',
      unit: 'ratio',
      value: successRatio.value,
      target: TARGETS.bookingSuccess,
      trigger: 'Below 99.5% over any 1 h window',
      triggered: hourRatio.value !== null && hourRatio.value < TARGETS.bookingSuccess,
      sample: successRatio.denominator,
    },
    {
      id: 'availability_live',
      label: 'Availability feels live (p95, last hour)',
      unit: 'seconds',
      value: p95.value,
      target: TARGETS.realtimeP95Seconds,
      trigger: 'p95 above 2 s for 15 min',
      triggered: p95.value !== null && p95.value > TARGETS.realtimeP95Seconds,
      sample: p95.count,
    },
    {
      id: 'bookers_invite',
      label: 'Bookers become inviters',
      unit: 'ratio',
      value: inviteAny.value,
      target: TARGETS.inviteRate,
      trigger: 'Below 25% for 7 days',
      triggered: inviteAny.value !== null && inviteAny.value < TARGETS.inviteRateTrigger,
      sample: bookers,
    },
    {
      id: 'invites_convert_vouch',
      label: 'Vouch invites turn into guests',
      unit: 'ratio',
      value: vouch.value,
      target: TARGETS.vouchOpenToClaim,
      trigger: 'Below 20% for 7 days',
      triggered: vouch.value !== null && vouch.value < TARGETS.vouchOpenToClaimTrigger,
      sample: vouch.denominator,
    },
    {
      id: 'invites_convert_public',
      label: 'Public links turn into guests',
      unit: 'ratio',
      value: pub.value,
      target: null,
      trigger: 'Target set from the week-1 baseline',
      triggered: false,
      sample: pub.denominator,
    },
  ];

  const totalOpens = funnelRows.reduce((s, r) => s + r.opens, 0);
  const totalClaims = funnelRows.reduce((s, r) => s + r.claims, 0);
  return {
    generatedAt: new Date().toISOString(),
    days: input.days,
    goals,
    funnel: funnelRows,
    blendedOpenToClaim: ratio(totalClaims, totalOpens),
    inviteRate: [
      { rail: 'any', rate: inviteAny },
      { rail: 'vouch', rate: ratio(n(ir?.vouch), bookers) },
      { rail: 'public', rate: ratio(n(ir?.public), bookers) },
    ],
    kFactor: RAILS.map((rail) => {
      const r = byRail(kFactor.rows, rail);
      const k = ratio(n(r?.new_users), n(r?.inviters));
      return { rail, newUsers: k.numerator, inviters: k.denominator, value: k.value };
    }),
    plansHappened: ratio(n(plans.rows[0]?.happened), n(plans.rows[0]?.reached)),
    guardrail: {
      invited,
      organic,
      ratio: guardRatio,
      triggered: guardRatio !== null && guardRatio > TARGETS.guardrailRatio,
    },
    holdout: (['exposed', 'holdout'] as const).map((arm) => {
      const h = holdout.rows.find((r) => r.arm === arm);
      const p = holdoutPlans.rows.find((r) => r.arm === arm);
      return {
        arm,
        users: n(h?.users),
        bookers: n(h?.bookers),
        newUsersPerBooker: ratio(n(h?.new_users), n(h?.bookers)),
        plansHappened: ratio(n(p?.happened), n(p?.reached)),
      };
    }),
    audit: {
      ranAt: input.audit ? input.audit.ranAt.toISOString() : null,
      failures: input.audit ? input.audit.failures.length : null,
    },
  };
}
