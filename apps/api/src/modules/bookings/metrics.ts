import { metrics, type MeterProvider } from '@opentelemetry/api';

/** `path` label: direct bookings now; S4 adds `claim`. */
export type BookingPath = 'direct' | 'claim';

/** Labels are only `outcome` and `path`; never activity, user or booking IDs (CLAUDE.md, NFR-005). */
export function createBookingMetrics(provider: MeterProvider = metrics.getMeterProvider()) {
  const meter = provider.getMeter('velio-bookings');
  return {
    attempts: meter.createCounter('booking_attempts_total', { description: 'Booking attempts by outcome' }),
    duration: meter.createHistogram('booking_duration_seconds', {
      description: 'Booking engine duration, checks to commit',
      unit: 's',
    }),
    rowWait: meter.createHistogram('booking_row_wait_seconds', {
      description: 'Time in the conditional spot UPDATE, including the activity row lock wait',
      unit: 's',
    }),
    removals: meter.createCounter('booking_removals_total', { description: 'Host removals by outcome' }),
    oversell: meter.createCounter('oversell_detected_total', {
      description: 'Activities whose confirmed bookings differ from capacity minus spots left',
    }),
  };
}

export type BookingMetrics = ReturnType<typeof createBookingMetrics>;
