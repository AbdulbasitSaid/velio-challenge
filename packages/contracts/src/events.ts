import { z } from 'zod';

/** Web Vitals the web app reports (S8 FR-007). Timings in milliseconds; CLS is unitless. */
export const WebVitalMetric = z.enum(['FCP', 'LCP', 'TTFB', 'CLS', 'INP']);
export type WebVitalMetric = z.infer<typeof WebVitalMetric>;

/** Page templates: a closed list, so the metric label stays low-cardinality (CLAUDE.md). */
export const VitalPage = z.enum(['activity', 'invite', 'community', 'other']);

/** `navigator.connection.effectiveType`, where the browser exposes it. */
export const ConnectionType = z.enum(['slow-2g', '2g', '3g', '4g']);

/**
 * Client analytics (S8 FR-006). Only these names are accepted. `activity_viewed` is stored as a
 * funnel event; `web_vital` becomes a histogram sample and is never stored.
 */
export const ClientEvent = z
  .discriminatedUnion('name', [
    z.object({
      name: z.literal('activity_viewed'),
      activityId: z.uuid(),
      platform: z.enum(['web', 'ios', 'android']).optional(),
    }),
    z.object({
      name: z.literal('web_vital'),
      metric: WebVitalMetric,
      value: z.number().min(0).max(600_000),
      page: VitalPage,
      connection: ConnectionType.optional(),
    }),
  ])
  .meta({ id: 'ClientEvent' });
export type ClientEvent = z.infer<typeof ClientEvent>;
