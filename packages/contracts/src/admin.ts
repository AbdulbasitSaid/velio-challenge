import { z } from 'zod';

const Rail = z.enum(['vouch', 'public']);

/** A ratio with its parts; `value` is null when the denominator is 0 (S8 business rules). */
export const Ratio = z
  .object({ numerator: z.number().int(), denominator: z.number().int(), value: z.number().nullable() })
  .meta({ id: 'Ratio' });
export type Ratio = z.infer<typeof Ratio>;

/** One PRD goal (Problem and goals, Success metrics). `target` null: set after the week-1 baseline (D1). */
export const AdminGoal = z
  .object({
    id: z.enum([
      'no_oversell',
      'booking_success',
      'availability_live',
      'bookers_invite',
      'invites_convert_vouch',
      'invites_convert_public',
    ]),
    label: z.string(),
    unit: z.enum(['count', 'ratio', 'seconds']),
    value: z.number().nullable(),
    target: z.number().nullable(),
    /** The PRD trigger, in words. */
    trigger: z.string(),
    triggered: z.boolean(),
    /** Sample size behind `value`. */
    sample: z.number().int(),
  })
  .meta({ id: 'AdminGoal' });
export type AdminGoal = z.infer<typeof AdminGoal>;

/** The admin metrics page (S8 FR-009): aggregates only, never people (SEC-002). */
export const AdminMetrics = z
  .object({
    generatedAt: z.iso.datetime({ offset: true }),
    days: z.number().int(),
    goals: z.array(AdminGoal),
    funnel: z.array(
      z.object({
        rail: Rail,
        invites: z.number().int(),
        opens: z.number().int(),
        claims: z.number().int(),
        openToClaim: Ratio,
      }),
    ),
    /** Blended open-to-claim, for context only; never a trigger (D1). */
    blendedOpenToClaim: Ratio,
    inviteRate: z.array(z.object({ rail: z.enum(['any', 'vouch', 'public']), rate: Ratio })),
    kFactor: z.array(
      z.object({
        rail: Rail,
        newUsers: z.number().int(),
        inviters: z.number().int(),
        value: z.number().nullable(),
      }),
    ),
    plansHappened: Ratio,
    guardrail: z.object({
      invited: Ratio,
      organic: Ratio,
      /** invited ÷ organic; the PRD trigger is > 1.5. */
      ratio: z.number().nullable(),
      triggered: z.boolean(),
    }),
    holdout: z.array(
      z.object({
        arm: z.enum(['exposed', 'holdout']),
        users: z.number().int(),
        bookers: z.number().int(),
        newUsersPerBooker: Ratio,
        plansHappened: Ratio,
      }),
    ),
    audit: z.object({
      ranAt: z.iso.datetime({ offset: true }).nullable(),
      failures: z.number().int().nullable(),
    }),
  })
  .meta({ id: 'AdminMetrics' });
export type AdminMetrics = z.infer<typeof AdminMetrics>;

/** An upcoming activity in the kill-switch list (S8 FR-012). */
export const AdminActivity = z
  .object({
    id: z.uuid(),
    title: z.string(),
    communityName: z.string(),
    startsAt: z.iso.datetime({ offset: true }),
    timezone: z.string(),
    capacity: z.number().int(),
    spotsLeft: z.number().int(),
    bookingsPaused: z.boolean(),
  })
  .meta({ id: 'AdminActivity' });
export type AdminActivity = z.infer<typeof AdminActivity>;

export const AdminActivityList = z
  .object({ activities: z.array(AdminActivity) })
  .meta({ id: 'AdminActivityList' });
export type AdminActivityList = z.infer<typeof AdminActivityList>;

/** The attribution audit (PRD Operations, S8 FR-013): hash chains that fail verification. */
export const AdminAudit = z
  .object({
    ranAt: z.iso.datetime({ offset: true }),
    failures: z.array(z.object({ activityId: z.uuid(), table: z.string(), firstBadSeq: z.number().int() })),
  })
  .meta({ id: 'AdminAudit' });
export type AdminAudit = z.infer<typeof AdminAudit>;
