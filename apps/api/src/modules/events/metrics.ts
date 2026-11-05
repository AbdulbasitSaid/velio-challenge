import { metrics, type MeterProvider } from '@opentelemetry/api';

const VITAL_BUCKETS_S = [0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 4, 5, 7.5, 10, 15, 20, 30];
const CLS_BUCKETS = [0, 0.05, 0.1, 0.15, 0.25, 0.5, 1];

/** Labels are only `name`, `metric`, `page` and `connection`: closed lists, never IDs (CLAUDE.md). */
export function createEventMetrics(provider: MeterProvider = metrics.getMeterProvider()) {
  const meter = provider.getMeter('velio-events');
  return {
    received: meter.createCounter('client_events_total', { description: 'Client events accepted, by name' }),
    vitals: meter.createHistogram('web_vitals_seconds', {
      description: 'Real-user Web Vitals timings (FCP, LCP, TTFB, INP) from the web app',
      unit: 's',
      advice: { explicitBucketBoundaries: VITAL_BUCKETS_S },
    }),
    cls: meter.createHistogram('web_vitals_cls', {
      description: 'Real-user Cumulative Layout Shift from the web app',
      advice: { explicitBucketBoundaries: CLS_BUCKETS },
    }),
  };
}

export type EventMetrics = ReturnType<typeof createEventMetrics>;
