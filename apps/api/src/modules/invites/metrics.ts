import { metrics, type MeterProvider } from '@opentelemetry/api';

/** Labels are only `rail`, `outcome` or `scope`; never invite, plan, user or activity IDs or codes. */
export function createInviteMetrics(provider: MeterProvider = metrics.getMeterProvider()) {
  const meter = provider.getMeter('velio-invites');
  return {
    created: meter.createCounter('invites_created_total', { description: 'Invites created, by rail' }),
    opens: meter.createCounter('invite_opens_total', {
      description: 'Open beacons by rail and outcome (recorded, duplicate, member, bot)',
    }),
    rateLimited: meter.createCounter('rate_limited_total', {
      description: 'Requests refused by a rate limit, by scope (code, link)',
    }),
    autoPaused: meter.createCounter('invite_auto_paused_total', {
      description: 'Public links paused automatically (PRD R7)',
    }),
    contactMismatch: meter.createCounter('vouch_contact_mismatch_total', {
      description: 'Vouch claims whose contact differs from the one the inviter entered',
    }),
  };
}

export type InviteMetrics = ReturnType<typeof createInviteMetrics>;
