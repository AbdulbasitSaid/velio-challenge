import { z } from 'zod';
import { ActivityState } from './activities';

export const Booking = z
  .object({
    id: z.uuid(),
    /** `VLO-` and five characters (PRD business rules). */
    ref: z.string().meta({ example: 'VLO-7K2MX' }),
    activityId: z.uuid(),
    planId: z.uuid(),
    source: z.enum(['direct', 'vouch', 'public']),
    status: z.enum(['confirmed', 'removed']),
    createdAt: z.iso.datetime({ offset: true }),
  })
  .meta({ id: 'Booking' });
export type Booking = z.infer<typeof Booking>;

export const BookingResponse = z
  .object({
    booking: Booking,
    activity: ActivityState,
  })
  .meta({ id: 'BookingResponse' });
export type BookingResponse = z.infer<typeof BookingResponse>;

/** 1–128 characters from `[A-Za-z0-9_-]`; a UUID fits. */
export const IdempotencyKey = z
  .string()
  .regex(/^[A-Za-z0-9_-]{1,128}$/)
  .meta({ example: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f' });
