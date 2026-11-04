// Seeds a load run through the public API (no test-only bypasses, MVP plan §4.13): signs in a host
// and creates the run's activities.
//   bun load/seed.ts           last_spot_race: one activity per spot count → results/seed.json
//   bun load/seed.ts viewers   viewers (S3): one 14-spot activity        → results/seed-viewers.json
import { resolve } from 'node:path';

const API_URL = process.env.API_URL ?? 'http://localhost:3001';
const viewers = process.argv[2] === 'viewers';
const SPOTS = viewers ? [14] : [1, 5, 14];
const VUS_PER_ACTIVITY = 25;
/** 5% of the 5,000-viewer target (MVP plan §4.13 smoke sizing). */
const VIEWERS = 250;

const runId = new Date().toISOString().replace(/[-:.]/g, '').slice(0, 15);

async function post(path: string, body: unknown, headers: Record<string, string> = {}) {
  const res = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${path}: ${res.status} ${await res.text()}`);
  return res.json() as Promise<Record<string, unknown>>;
}

const session = await post(
  '/api/sessions',
  { displayName: `Load ${runId} Host`, contact: `load-${runId}-host@example.com` },
  { 'x-client': 'mobile', 'x-device-id': `load-${runId}-host` },
);
const auth = { authorization: `Bearer ${session.token as string}` };

const activities = [];
for (const spots of SPOTS) {
  const activity = await post(
    '/api/activities',
    {
      communitySlug: 'explore-kenya',
      title: `Load ${runId} ${viewers ? 'viewers' : 'last_spot_race'} ${spots}`,
      startsAt: new Date(Date.now() + 7 * 86_400_000).toISOString(),
      timezone: 'Africa/Nairobi',
      location: {
        venueName: 'Load test venue',
        addressText: 'Nowhere, Kenya',
        lat: -1.2921,
        lng: 36.8219,
      },
      priceMinor: 100,
      currency: 'KES',
      capacity: spots,
    },
    auth,
  );
  activities.push({ id: activity.id as string, spots });
}

const seed = { runId, vusPerActivity: VUS_PER_ACTIVITY, activities, ...(viewers && { viewers: VIEWERS }) };
const file = viewers ? 'results/seed-viewers.json' : 'results/seed.json';
await Bun.write(resolve(import.meta.dir, file), `${JSON.stringify(seed, null, 2)}\n`);
console.log(`Seeded run ${runId}: ${activities.map((a) => `${a.spots} spot(s)`).join(', ')}`);
