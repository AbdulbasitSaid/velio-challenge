// Client analytics (S8 FR-006, FR-007): activity views and real-user Web Vitals, sent to /api/events.
// Best-effort: a lost event never affects the page. No personal data is sent.
import type { ClientEvent } from '@velio/contracts';
import { useEffect } from 'react';
import { apiFetch } from './api/client';

export function sendEvent(event: ClientEvent) {
  void apiFetch('/events', { method: 'POST', body: event, keepalive: true }).catch(() => undefined);
}

/** `activity_viewed` once per page load, after the first paint (bots that never paint send nothing). */
export function useActivityViewed(activityId: string) {
  useEffect(() => {
    const frame = requestAnimationFrame(() =>
      sendEvent({ name: 'activity_viewed', activityId, platform: 'web' }),
    );
    return () => cancelAnimationFrame(frame);
  }, [activityId]);
}

type Page = Extract<ClientEvent, { name: 'web_vital' }>['page'];
type Connection = Extract<ClientEvent, { name: 'web_vital' }>['connection'];
const VITALS = new Set(['FCP', 'LCP', 'TTFB', 'CLS', 'INP']);
const CONNECTIONS = new Set(['slow-2g', '2g', '3g', '4g']);

/** The page template from the path: a closed list, so the metric label stays small (CLAUDE.md). */
export function vitalPage(pathname: string): Page {
  if (pathname.startsWith('/activities/')) return 'activity';
  if (pathname.startsWith('/i/')) return 'invite';
  if (pathname === '/' || pathname.startsWith('/communities/')) return 'community';
  return 'other';
}

/** A Web Vitals report as a `web_vital` event, or null for metrics the API doesn't take. */
export function vitalEvent(
  metric: { name: string; value: number },
  pathname: string,
  effectiveType?: string,
): ClientEvent | null {
  if (!VITALS.has(metric.name) || !Number.isFinite(metric.value) || metric.value < 0) return null;
  return {
    name: 'web_vital',
    metric: metric.name as 'FCP',
    value: Math.min(metric.value, 600_000),
    page: vitalPage(pathname),
    connection: effectiveType && CONNECTIONS.has(effectiveType) ? (effectiveType as Connection) : undefined,
  };
}
