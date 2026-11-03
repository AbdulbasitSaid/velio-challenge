import { randomUUID } from 'node:crypto';
import type { App } from '../../src/app';
import { json } from './app';

/** `app.request` in process, or `fetch` against a running server (concurrency tests). */
export type Requester = (path: string, init?: RequestInit) => Promise<Response>;

export const inProcess =
  (app: App): Requester =>
  (path, init) =>
    Promise.resolve(app.request(path, init));

export const overHttp =
  (baseUrl: string): Requester =>
  (path, init) =>
    fetch(`${baseUrl}${path}`, init);

export interface Caller {
  id: string;
  headers: Record<string, string>;
}

/** Signs in through `POST /api/sessions` as a mobile client and returns bearer headers. */
export async function signIn(
  request: Requester,
  displayName: string,
  contact = `${randomUUID()}@example.com`,
) {
  const res = await request('/api/sessions', json({ displayName, contact }, { 'x-client': 'mobile' }));
  if (res.status !== 201) throw new Error(`sign-in failed: ${res.status}`);
  const body = (await res.json()) as { user: { id: string }; token: string };
  return { id: body.user.id, headers: { authorization: `Bearer ${body.token}` } } satisfies Caller;
}

/** Signs in `count` people, a few at a time so the pool isn't the bottleneck of setup. */
export async function signInMany(request: Requester, count: number, prefix = 'Guest'): Promise<Caller[]> {
  const out: Caller[] = [];
  for (let i = 0; i < count; i += 20) {
    const batch = Array.from({ length: Math.min(20, count - i) }, (_, j) =>
      signIn(request, `${prefix} ${i + j}`),
    );
    out.push(...(await Promise.all(batch)));
  }
  return out;
}

export const DAY_MS = 86_400_000;

export function activityBody(overrides: Record<string, unknown> = {}) {
  return {
    communitySlug: 'explore-kenya',
    title: 'Sunset Kayaking',
    description: 'Two hours on the lake.',
    startsAt: new Date(Date.now() + 30 * DAY_MS).toISOString(),
    timezone: 'Africa/Nairobi',
    location: {
      placeId: 'ChIJ_example',
      venueName: 'Lake Naivasha Boat Club',
      addressText: 'Moi South Lake Rd, Naivasha, Kenya',
      lat: -0.7667,
      lng: 36.4333,
      meetingPoint: 'Meet at the blue gate by the jetty',
    },
    priceMinor: 350000,
    currency: 'KES',
    capacity: 14,
    ...overrides,
  };
}

export interface HostActivityBody {
  id: string;
  hostId: string;
  capacity: number;
  spotsLeft: number;
  bookedCount: number;
  version: number;
  title: string;
  description: string;
  startsAt: string;
  location: { lat: number; meetingPoint: string | null };
}

export async function createActivity(
  request: Requester,
  host: Caller,
  overrides: Record<string, unknown> = {},
) {
  const res = await request('/api/activities', json(activityBody(overrides), host.headers));
  if (res.status !== 201) throw new Error(`create activity failed: ${res.status} ${await res.text()}`);
  return (await res.json()) as HostActivityBody;
}

export function book(request: Requester, caller: Caller, activityId: string, key: string = randomUUID()) {
  return request(`/api/activities/${activityId}/bookings`, {
    method: 'POST',
    headers: { ...caller.headers, 'idempotency-key': key },
  });
}

export function patchActivity(request: Requester, caller: Caller, activityId: string, body: unknown) {
  return request(`/api/activities/${activityId}`, {
    method: 'PATCH',
    headers: { ...caller.headers, 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

export function removeBooking(request: Requester, caller: Caller, bookingId: string) {
  return request(`/api/host/bookings/${bookingId}/removal`, { method: 'POST', headers: caller.headers });
}

export interface BookingBody {
  booking: { id: string; ref: string; activityId: string; planId: string; source: string; status: string };
  activity: { id: string; spotsLeft: number; version: number };
}

export async function errorCode(res: Response): Promise<string> {
  return ((await res.json()) as { error: { code: string } }).error.code;
}
