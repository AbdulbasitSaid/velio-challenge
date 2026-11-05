import { metrics, type MeterProvider } from '@opentelemetry/api';
import { LATENCY_BUCKETS_S } from '../../telemetry/buckets';
import type { RealtimePlatform } from '@velio/contracts';

export type EventType = 'spots' | 'plan' | 'attendance' | 'resync';

/**
 * Seconds, dense around the PRD's 2 s target. The SDK's default boundaries (0, 5, 10, …) would put
 * every sample in the first bucket and make p95 unreadable.
 */

/**
 * Realtime instruments (S3 NFR-003, MVP plan §4.12). Labels are only `platform` or `type`; never
 * activity, plan, user or topic IDs.
 */
export function createRealtimeMetrics(
  openSockets: () => Map<RealtimePlatform, number>,
  provider: MeterProvider = metrics.getMeterProvider(),
) {
  const meter = provider.getMeter('velio-realtime');
  meter
    .createObservableGauge('realtime_open_sockets', { description: 'Open WebSocket connections' })
    .addCallback((result) => {
      for (const [platform, count] of openSockets()) result.observe(count, { platform });
    });
  return {
    commitToAck: meter.createHistogram('realtime_commit_to_ack_seconds', {
      description: 'Database commit to client render acknowledgement, on the server clock',
      unit: 's',
      advice: { explicitBucketBoundaries: LATENCY_BUCKETS_S },
    }),
    notifyLag: meter.createHistogram('realtime_notify_lag_seconds', {
      description: 'Database commit to the listener receiving the notification',
      unit: 's',
      advice: { explicitBucketBoundaries: LATENCY_BUCKETS_S },
    }),
    reconnects: meter.createCounter('realtime_reconnects_total', {
      description: 'Connections made with resume=1',
    }),
    published: meter.createCounter('realtime_events_published_total', {
      description: 'Events published to topics, by type',
    }),
    acksIgnored: meter.createCounter('realtime_acks_ignored_total', {
      description: 'Render acknowledgements not counted: unknown, expired, duplicate or unsubscribed',
    }),
    listenerReconnects: meter.createCounter('realtime_listener_reconnects_total', {
      description: 'Times the LISTEN connection came back after dropping',
    }),
  };
}

export type RealtimeMetrics = ReturnType<typeof createRealtimeMetrics>;
