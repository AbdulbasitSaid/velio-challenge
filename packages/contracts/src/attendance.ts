import { z } from 'zod';
import { ActivityCard } from './activities';
import { MemberPerson } from './people';

export const HostActivityList = z
  .object({
    upcoming: z.array(ActivityCard.extend({ bookedCount: z.number().int() })),
    past: z.array(ActivityCard.extend({ bookedCount: z.number().int() })),
  })
  .meta({ id: 'HostActivityList' });
export type HostActivityList = z.infer<typeof HostActivityList>;

export const AttendanceMark = z.enum(['attended', 'no_show']).meta({ id: 'AttendanceMark' });

/** PRD H1, D5: names, refs and sources; never contacts or invite notes. */
export const Attendee = z
  .object({
    bookingId: z.uuid(),
    ref: z.string(),
    status: z.enum(['confirmed', 'removed']),
    person: MemberPerson,
    bookedAt: z.iso.datetime({ offset: true }),
    source: z.enum(['direct', 'vouch', 'public']),
    invitedBy: MemberPerson.nullable(),
    planId: z.uuid(),
    mark: AttendanceMark.nullable(),
    markedAt: z.iso.datetime({ offset: true }).nullable(),
  })
  .meta({ id: 'Attendee' });
export type Attendee = z.infer<typeof Attendee>;

export const Attendance = z
  .object({
    activity: z.object({
      id: z.uuid(),
      capacity: z.number().int(),
      spotsLeft: z.number().int(),
      version: z.number().int(),
      startsAt: z.iso.datetime({ offset: true }),
      timezone: z.string(),
      started: z.boolean(),
    }),
    attendees: z.array(Attendee),
  })
  .meta({ id: 'Attendance' });
export type Attendance = z.infer<typeof Attendance>;

export const AttendanceMarkCreate = z.object({ mark: AttendanceMark }).meta({ id: 'AttendanceMarkCreate' });
