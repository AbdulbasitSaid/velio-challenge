// Server-side API access for server components and route handlers. Forwards the viewer's cookie, device
// ID, client IP and trace context, and adds CloudFront's origin header so the API's lockdown passes.
import { cookies, headers } from 'next/headers';
import type { z } from 'zod';
import { DEVICE_COOKIE, DEVICE_HEADER } from '../device';
import { request, type ApiInit, type Transport } from './client';

const FORWARDED = ['x-forwarded-for', 'traceparent', 'tracestate', 'user-agent', 'accept-language'] as const;

export const serverTransport: Transport = {
  baseUrl: process.env.API_INTERNAL_URL ?? 'http://localhost:3001',
  headers: async () => {
    const [incoming, jar] = await Promise.all([headers(), cookies()]);
    const out: Record<string, string> = {};
    const cookie = incoming.get('cookie');
    if (cookie) out.cookie = cookie;
    const device = jar.get(DEVICE_COOKIE)?.value;
    if (device) out[DEVICE_HEADER] = device;
    for (const name of FORWARDED) {
      const value = incoming.get(name);
      if (value) out[name] = value;
    }
    if (process.env.ORIGIN_VERIFY_SECRET) out['x-origin-verify'] = process.env.ORIGIN_VERIFY_SECRET;
    return out;
  },
};

export function serverFetch<S extends z.ZodType | undefined = undefined>(path: string, init?: ApiInit<S>) {
  return request(serverTransport, path, init);
}
