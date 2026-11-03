// last_spot_race (MVP plan §4.13): per seeded activity, 25 VUs book at once. Pass/fail is exact:
// N bookings succeed and the rest get sold_out. Run through `bun run load:smoke`.
import exec from 'k6/execution';
import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

const API_URL = __ENV.API_URL || 'http://host.docker.internal:3001';
const seed = JSON.parse(open('/load/results/seed.json'));

const booked = new Counter('booked');
const soldOut = new Counter('sold_out');

const scenarios = {};
const thresholds = { checks: ['rate==1'] };
for (const a of seed.activities) {
  scenarios[`spots_${a.spots}`] = {
    executor: 'per-vu-iterations',
    vus: seed.vusPerActivity,
    iterations: 1,
    exec: 'race',
    env: { ACTIVITY_ID: a.id },
    tags: { spots: String(a.spots) },
  };
  thresholds[`booked{spots:${a.spots}}`] = [`count==${a.spots}`];
  thresholds[`sold_out{spots:${a.spots}}`] = [`count==${seed.vusPerActivity - a.spots}`];
}

export const options = { scenarios, thresholds };

// Every VU gets its own person and session, signed in through the API before the race starts.
export function setup() {
  const tokens = {};
  for (const a of seed.activities) {
    const requests = Array.from({ length: seed.vusPerActivity }, (_, i) => {
      const name = `load-${seed.runId}-${a.spots}-${i}`;
      return {
        method: 'POST',
        url: `${API_URL}/api/sessions`,
        body: JSON.stringify({ displayName: `Load ${seed.runId} Guest`, contact: `${name}@example.com` }),
        params: {
          headers: { 'content-type': 'application/json', 'x-client': 'mobile', 'x-device-id': name },
        },
      };
    });
    tokens[a.id] = http.batch(requests).map((res) => {
      if (res.status !== 201) throw new Error(`sign-in failed: ${res.status}`);
      return res.json('token');
    });
  }
  return { tokens };
}

export function race(data) {
  const activityId = __ENV.ACTIVITY_ID;
  const i = exec.scenario.iterationInTest;
  const res = http.post(`${API_URL}/api/activities/${activityId}/bookings`, null, {
    headers: {
      authorization: `Bearer ${data.tokens[activityId][i]}`,
      'idempotency-key': `load-${seed.runId}-${activityId}-${i}`,
      'x-client': 'web',
    },
    tags: { name: 'POST /api/activities/:id/bookings' },
  });
  const code = res.status === 201 ? 'booked' : res.json('error.code');
  check(res, {
    'booked or sold_out': () => code === 'booked' || (res.status === 409 && code === 'sold_out'),
  });
  if (code === 'booked') booked.add(1);
  if (code === 'sold_out') soldOut.add(1);
}

export function handleSummary(data) {
  const lines = [`last_spot_race ${seed.runId}`];
  for (const a of seed.activities) {
    const b = data.metrics[`booked{spots:${a.spots}}`];
    const s = data.metrics[`sold_out{spots:${a.spots}}`];
    lines.push(
      `  ${a.spots} spot(s): booked=${b ? b.values.count : 0} sold_out=${s ? s.values.count : 0} (expected ${a.spots} / ${seed.vusPerActivity - a.spots})`,
    );
  }
  const d = data.metrics.http_req_duration.values;
  lines.push(`  checks rate=${data.metrics.checks.values.rate}`);
  lines.push(
    `  http_req_duration avg=${d.avg.toFixed(1)}ms p(95)=${d['p(95)'].toFixed(1)}ms max=${d.max.toFixed(1)}ms`,
  );
  return {
    stdout: `${lines.join('\n')}\n`,
    [`/load/results/k6-${seed.runId}.json`]: JSON.stringify(data, null, 2),
  };
}
