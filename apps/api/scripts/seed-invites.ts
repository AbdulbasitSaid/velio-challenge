// Seeds one invite per S6 screen state (S6 VALIDATION preconditions) through the public API, plus two
// direct database updates the API can't make on purpose (a started activity, paused bookings).
// Local development only:
//   bun apps/api/scripts/seed-invites.ts
// Prints the invite links. Seeded rows are named "Seed <run> …".
import postgres from 'postgres';

const API_URL = process.env.API_URL ?? 'http://localhost:3001';
const WEB_URL = process.env.WEB_URL ?? 'http://localhost:3000';
const DB_URL = process.env.SEED_DATABASE_URL ?? 'postgres://postgres@localhost:5432/velio';
const run = new Date()
  .toISOString()
  .replace(/[-:.TZ]/g, '')
  .slice(4, 12);

type Json = Record<string, unknown>;

async function call(
  method: string,
  path: string,
  body?: unknown,
  headers: Record<string, string> = {},
): Promise<Json> {
  const res = await fetch(`${API_URL}/api${path}`, {
    method,
    headers: { 'content-type': 'application/json', 'x-client': 'mobile', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${method} ${path}: ${res.status} ${await res.text()}`);
  return res.status === 204 ? {} : ((await res.json()) as Json);
}

async function person(name: string) {
  const slug = name.toLowerCase().replace(/\s+/g, '.');
  const s = await call(
    'POST',
    '/sessions',
    { displayName: name, contact: `${slug}.${run}@example.com` },
    {
      'x-device-id': `seed-${run}-${slug.replace(/\./g, '-')}`,
    },
  );
  return { authorization: `Bearer ${s.token as string}` };
}

const amara = await person('Amara Wanjiru');
const tunde = await person('Tunde Adeyemi');
const imani = await person('Imani Kariuki');

async function activity(title: string, capacity: number) {
  return call(
    'POST',
    '/activities',
    {
      communitySlug: 'explore-kenya',
      title: `Seed ${run} ${title}`,
      description:
        'Two hours on Lake Naivasha as the sun drops. Stable sit-on-top kayaks, a guide at the front and back, and hippos kept at a respectful distance.',
      startsAt: new Date(Date.now() + 9 * 86_400_000).toISOString(),
      timezone: 'Africa/Nairobi',
      location: {
        venueName: 'Lake Naivasha Boat Club',
        addressText: 'Moi South Lake Rd, Naivasha, Kenya',
        lat: -0.7667,
        lng: 36.4333,
        meetingPoint: 'Meet at the blue gate by the jetty, 15 minutes before',
      },
      priceMinor: 350000,
      currency: 'KES',
      capacity,
    },
    amara,
  );
}

async function book(activityId: string, who: Record<string, string>) {
  const r = await call(
    'POST',
    `/activities/${activityId}/bookings`,
    {},
    { ...who, 'idempotency-key': crypto.randomUUID() },
  );
  return (r.booking as Json).planId as string;
}

async function invite(planId: string, body: Json, who = tunde) {
  return (await call('POST', `/plans/${planId}/invites`, body, who)).code as string;
}

const links: [string, string][] = [];
const vouch = {
  rail: 'vouch',
  inviteeName: 'Zainab',
  note: 'Sunset on the lake, then nyama choma in town after. You’ll love it.',
};

// G1 vouch and G2 public, on one activity with spots.
const open = await activity('Sunset Kayaking', 14);
const openPlan = await book(open.id as string, tunde);
links.push(['G1 vouch (claimable)', await invite(openPlan, vouch)]);
links.push(['G2 public (claimable)', await invite(openPlan, { rail: 'public' })]);

// G5 sold out: two spots, both booked.
const full = await activity('Sold out kayaking', 2);
const fullPlan = await book(full.id as string, tunde);
links.push(['G5 sold out (vouch)', await invite(fullPlan, vouch)]);
await book(full.id as string, imani);

// G7 other: a vouch someone else claimed.
const claimed = await invite(openPlan, { rail: 'vouch', inviteeName: 'Omar' });
await call(
  'POST',
  `/invites/${claimed}/claims`,
  { displayName: 'Omar Mwangi', contact: `omar.${run}@example.com` },
  {
    'idempotency-key': crypto.randomUUID(),
    'x-device-id': `seed-${run}-omar`,
  },
);
links.push(['G7 claimed by someone else', claimed]);

// Paused public link: one public link per Plan, so on Imani's own Plan.
const imaniPlan = await book(open.id as string, imani);
const paused = await invite(imaniPlan, { rail: 'public' }, imani);
await call('POST', `/invites/${paused}/pause`, undefined, imani);
links.push(['Paused public link', paused]);

// G6 expired and bookings paused: direct updates (the API refuses both on purpose).
const db = postgres(DB_URL, { max: 1 });
const started = await activity('Started kayaking', 14);
const startedPlan = await book(started.id as string, tunde);
links.push(['G6 expired (activity started)', await invite(startedPlan, vouch)]);
// The lock trigger (VL001) refuses moving a booked activity's start; seeding skips triggers for this row.
await db.begin(async (tx) => {
  await tx`set local session_replication_role = replica`;
  await tx`update activities set starts_at = now() - interval '1 hour' where id = ${started.id as string}`;
});

const pausedBookings = await activity('Bookings paused kayaking', 14);
const pausedPlan = await book(pausedBookings.id as string, tunde);
links.push(['Bookings paused', await invite(pausedPlan, vouch)]);
await db`update activities set bookings_paused = true where id = ${pausedBookings.id as string}`;
await db.end();

links.push(['G9 unknown code', '23456A']);
for (const [label, code] of links) console.log(`${label.padEnd(32)} ${WEB_URL}/i/${code}`);
