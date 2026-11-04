import { z } from 'zod';
import { ActivityCard } from './activities';
import { InviteStatus, PauseReason } from './invites';
import { MemberPerson } from './people';

const Source = z.enum(['direct', 'vouch', 'public']);

/** An invite as another Plan member sees it: no code, link or note unless the viewer made it. */
export const PlanInvite = z
  .object({
    id: z.uuid(),
    rail: z.enum(['vouch', 'public']),
    inviteeName: z.string().nullable(),
    createdBy: MemberPerson,
    status: InviteStatus,
    opens: z.number().int(),
    claims: z.number().int(),
    paused: z.boolean(),
    pausedReason: PauseReason.nullable(),
    createdAt: z.iso.datetime({ offset: true }),
    code: z.string().optional(),
    link: z.string().optional(),
    note: z.string().nullable().optional(),
  })
  .meta({ id: 'PlanInvite' });

/** PRD L1. Full names, because only Plan members can read it (PRD Q12). */
export const PlanView = z
  .object({
    id: z.uuid(),
    activity: z.object({
      id: z.uuid(),
      title: z.string(),
      startsAt: z.iso.datetime({ offset: true }),
      timezone: z.string(),
    }),
    owner: MemberPerson,
    members: z.array(
      z.object({
        person: MemberPerson,
        source: Source,
        invitedBy: MemberPerson.nullable(),
        joinedAt: z.iso.datetime({ offset: true }),
      }),
    ),
    viewer: z.object({
      booking: z.object({ id: z.uuid(), ref: z.string(), status: z.enum(['confirmed', 'removed']) }),
      canInvite: z.boolean(),
    }),
    invites: z.array(PlanInvite),
  })
  .meta({ id: 'PlanView' });
export type PlanView = z.infer<typeof PlanView>;

export const MyPlan = z
  .object({
    planId: z.uuid(),
    activity: ActivityCard,
    booking: z.object({ id: z.uuid(), ref: z.string(), status: z.enum(['confirmed', 'removed']) }),
    members: z.object({ count: z.number().int(), preview: z.array(MemberPerson) }),
  })
  .meta({ id: 'MyPlan' });

/** PRD L2: upcoming soonest first, past most recent first. */
export const MyPlans = z.object({ upcoming: z.array(MyPlan), past: z.array(MyPlan) }).meta({ id: 'MyPlans' });
export type MyPlans = z.infer<typeof MyPlans>;
