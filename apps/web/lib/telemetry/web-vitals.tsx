'use client';

// Real-user Web Vitals (S8 FR-007; PRD: invite page first content under 1.5 s on mobile). Next's
// built-in reporter, so no extra dependency; each metric becomes one `web_vital` event.
import { useReportWebVitals } from 'next/web-vitals';
import { sendEvent, vitalEvent } from '../analytics';

export function WebVitals() {
  useReportWebVitals((metric) => {
    const connection = (navigator as Navigator & { connection?: { effectiveType?: string } }).connection;
    const event = vitalEvent(metric, location.pathname, connection?.effectiveType);
    if (event) sendEvent(event);
  });
  return null;
}
