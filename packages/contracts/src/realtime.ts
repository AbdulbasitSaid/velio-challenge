import { z } from 'zod';

/**
 * Realtime protocol over `GET /api/ws?platform=web|ios|android[&resume=1]` (S3 PLANNING §4.3–§4.5).
 *
 * Client rules (S5, S6 and S7 implement them):
 * 1. On every connect and reconnect, send `subscribe` first, then fetch the REST snapshot, so no
 *    event can fall between the two.
 * 2. Ignore a `spots` event whose `version` is less than or equal to the version on screen.
 * 3. While disconnected, poll `GET /api/activities/:id` every 10 seconds and show the data as
 *    stale ("Reconnecting"). Reconnect with `resume=1`.
 * 4. On `resync`, fetch every snapshot on screen again.
 * 5. On `plan`, fetch the Plan again; on `attendance`, fetch the attendance list again. These
 *    events carry only an ID, because what each person may see depends on who they are.
 * 6. After painting a `spots` version, send `rendered` with it (latency measurement).
 */

/** `activity:<id>` (anyone), `plan:<id>` (Plan members), `host:<activityId>` (the host). */
export const Topic = z
  .string()
  .regex(/^(activity|plan|host):[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
  .meta({ id: 'RealtimeTopic', example: 'activity:0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f' });
export type Topic = z.infer<typeof Topic>;

export const RealtimePlatform = z.enum(['web', 'ios', 'android']).meta({ id: 'RealtimePlatform' });
export type RealtimePlatform = z.infer<typeof RealtimePlatform>;

export const ClientMessage = z
  .discriminatedUnion('type', [
    z.object({ type: z.literal('subscribe'), topics: z.array(z.string()).min(1).max(20) }),
    z.object({ type: z.literal('unsubscribe'), topics: z.array(z.string()).min(1).max(20) }),
    z.object({ type: z.literal('rendered'), activityId: z.uuid(), version: z.number().int().nonnegative() }),
  ])
  .meta({ id: 'RealtimeClientMessage' });
export type ClientMessage = z.infer<typeof ClientMessage>;

export const SpotsEvent = z
  .object({
    type: z.literal('spots'),
    activityId: z.uuid(),
    spotsLeft: z.number().int(),
    version: z.number().int(),
    /** Database commit time; the latency reference. */
    committedAt: z.string(),
  })
  .meta({ id: 'RealtimeSpotsEvent' });
export type SpotsEvent = z.infer<typeof SpotsEvent>;

export const ServerMessage = z
  .discriminatedUnion('type', [
    z.object({ type: z.literal('subscribed'), topics: z.array(z.string()) }),
    SpotsEvent,
    z.object({ type: z.literal('plan'), planId: z.uuid() }),
    z.object({ type: z.literal('attendance'), activityId: z.uuid() }),
    z.object({ type: z.literal('resync') }),
    z.object({
      type: z.literal('error'),
      code: z.enum(['validation_failed', 'forbidden', 'not_found']),
      topic: z.string().optional(),
    }),
  ])
  .meta({ id: 'RealtimeServerMessage' });
export type ServerMessage = z.infer<typeof ServerMessage>;
