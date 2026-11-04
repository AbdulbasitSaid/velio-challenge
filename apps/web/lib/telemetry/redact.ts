// No personal data, codes or tokens in telemetry (CLAUDE.md). Next.js's built-in spans carry real URLs
// (`fetch GET http://api:3001/api/invites/K7PQ2N`, `http.target`), so every exported span's name and
// URL-shaped attributes are reduced to route templates, and query strings are dropped.
import type { Attributes } from '@opentelemetry/api';

const UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
// Invite codes and booking references follow /i/, /invites/ and /bookings/ path segments.
const CODE_AFTER = /(\/(?:i|invites|bookings)\/)[^/?#\s]+/gi;
const QUERY = /\?[^\s#]*/g;

export function redactText(text: string): string {
  return text.replace(QUERY, '').replace(UUID, ':id').replace(CODE_AFTER, '$1:code');
}

const URL_KEYS = new Set([
  'http.target',
  'http.url',
  'http.route',
  'url.full',
  'url.path',
  'url.query',
  'next.route',
  'next.rsc',
  'next.page',
]);

export function redactAttributes(attributes: Attributes): Attributes {
  const out: Attributes = {};
  for (const [key, value] of Object.entries(attributes)) {
    if (key === 'url.query' || key.startsWith('http.request.header') || key === 'user_agent.original')
      continue;
    out[key] = URL_KEYS.has(key) && typeof value === 'string' ? redactText(value) : value;
  }
  return out;
}
