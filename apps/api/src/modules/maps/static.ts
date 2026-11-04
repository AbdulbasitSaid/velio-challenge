import { createHmac } from 'node:crypto';

/** Signs Google Maps request URLs (path and query) with the URL-signing secret, as Google documents:
 * HMAC-SHA1 keyed with the URL-safe-base64-decoded secret, the result URL-safe base64 encoded. */
export function signUrl(url: string, secret: string): string {
  const { pathname, search } = new URL(url);
  const key = Buffer.from(secret.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
  const signature = createHmac('sha1', key)
    .update(pathname + search)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${url}&signature=${signature}`;
}

/** The activity's pin as a static image, or null when Static Maps isn't configured (PRD A7). */
export type StaticMapUrl = (lat: number, lng: number) => string | null;

export function staticMapUrl(config: {
  GOOGLE_MAPS_SERVER_KEY?: string;
  GOOGLE_MAPS_SIGNING_SECRET?: string;
}): StaticMapUrl {
  const key = config.GOOGLE_MAPS_SERVER_KEY;
  const secret = config.GOOGLE_MAPS_SIGNING_SECRET;
  if (!key || !secret) return () => null;
  return (lat, lng) => {
    const point = `${lat},${lng}`;
    const url = new URL('https://maps.googleapis.com/maps/api/staticmap');
    // Fixed size so the page reserves the box (no layout shift); forest marker from the tokens.
    url.searchParams.set('center', point);
    url.searchParams.set('zoom', '15');
    url.searchParams.set('size', '600x300');
    url.searchParams.set('scale', '2');
    url.searchParams.set('markers', `color:0x173600|${point}`);
    url.searchParams.set('key', key);
    return signUrl(url.toString(), secret);
  };
}
