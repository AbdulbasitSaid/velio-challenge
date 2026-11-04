// viewers (S3, MVP plan §4.13 at 5%): 250 anonymous sockets watch one 14-spot activity while 25 VUs
// race for its spots. Pass/fail: p95 of receive time − committedAt ≤ 2 s, no socket ever sees a
// version go backwards, every socket ends on spotsLeft = 0, and exactly 14 bookings succeed.
// Run through `bun run load:viewers`.
import exec from 'k6/execution';
import http from 'k6/http';
import { check } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { clearTimeout, setTimeout } from 'k6/timers';
import { WebSocket } from 'k6/websockets';

const API_URL = __ENV.API_URL || 'http://host.docker.internal:3001';
const WS_URL = API_URL.replace(/^http/, 'ws');
const seed = JSON.parse(open('/load/results/seed-viewers.json'));
const activity = seed.activities[0];

const latency = new Trend('spots_latency', true);
const regressions = new Counter('version_regressions');
const sawSoldOut = new Counter('viewers_saw_sold_out');
const booked = new Counter('booked');
const soldOut = new Counter('sold_out');

/** Sockets connect first; the race starts once they are all subscribed. */
const RACE_START_S = 10;
const VIEWER_DEADLINE_MS = (RACE_START_S + 30) * 1000;

export const options = {
  scenarios: {
    viewers: {
      executor: 'per-vu-iterations',
      vus: seed.viewers,
      iterations: 1,
      exec: 'watch',
      maxDuration: '60s',
    },
    race: {
      executor: 'per-vu-iterations',
      vus: seed.vusPerActivity,
      iterations: 1,
      exec: 'race',
      startTime: `${RACE_START_S}s`,
    },
  },
  thresholds: {
    checks: ['rate==1'],
    spots_latency: ['p(95)<=2000'],
    version_regressions: ['count==0'],
    viewers_saw_sold_out: [`count==${seed.viewers}`],
    booked: [`count==${activity.spots}`],
    sold_out: [`count==${seed.vusPerActivity - activity.spots}`],
  },
};

export function setup() {
  const requests = Array.from({ length: seed.vusPerActivity }, (_, i) => {
    const name = `load-${seed.runId}-viewers-${i}`;
    return {
      method: 'POST',
      url: `${API_URL}/api/sessions`,
      body: JSON.stringify({ displayName: `Load ${seed.runId} Guest`, contact: `${name}@example.com` }),
      params: { headers: { 'content-type': 'application/json', 'x-client': 'mobile', 'x-device-id': name } },
    };
  });
  const tokens = http.batch(requests).map((res) => {
    if (res.status !== 201) throw new Error(`sign-in failed: ${res.status}`);
    return res.json('token');
  });
  return { tokens };
}

// The client rules from packages/contracts/src/realtime.ts: subscribe, then take the snapshot,
// then apply only events with a higher version.
export function watch() {
  const ws = new WebSocket(`${WS_URL}/api/ws?platform=web`);
  // `version` is what the screen shows (snapshot or event); `lastEvent` the highest event seen.
  let version = -1;
  let lastEvent = -1;
  let done = false;
  let deadline;
  regressions.add(0);
  const finish = (ok) => {
    if (done) return;
    done = true;
    clearTimeout(deadline);
    check(null, { 'viewer saw sold out': () => ok });
    if (ok) sawSoldOut.add(1);
    ws.close();
  };
  ws.onopen = () => {
    ws.send(JSON.stringify({ type: 'subscribe', topics: [`activity:${activity.id}`] }));
  };
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (msg.type === 'subscribed') {
      const snap = http.get(`${API_URL}/api/activities/${activity.id}`, {
        tags: { name: 'GET /api/activities/:id' },
      });
      version = Math.max(version, snap.json('version'));
      if (snap.json('spotsLeft') === 0) finish(true);
      return;
    }
    if (msg.type !== 'spots') return;
    latency.add(Date.now() - Date.parse(msg.committedAt));
    // The server must deliver one activity's events in version order (S3 FR-011).
    if (msg.version < lastEvent) regressions.add(1);
    lastEvent = Math.max(lastEvent, msg.version);
    // Client rule: an event no newer than the screen is ignored (it may predate the snapshot).
    if (msg.version <= version) return;
    version = msg.version;
    ws.send(JSON.stringify({ type: 'rendered', activityId: activity.id, version: msg.version }));
    if (msg.spotsLeft === 0) finish(true);
  };
  ws.onerror = () => finish(false);
  deadline = setTimeout(() => finish(false), VIEWER_DEADLINE_MS);
}

export function race(data) {
  const i = exec.scenario.iterationInTest;
  const res = http.post(`${API_URL}/api/activities/${activity.id}/bookings`, null, {
    headers: {
      authorization: `Bearer ${data.tokens[i]}`,
      'idempotency-key': `load-${seed.runId}-viewers-${i}`,
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
  const v = (name, key) => (data.metrics[name] ? data.metrics[name].values[key] : 0);
  const lines = [
    `viewers ${seed.runId}`,
    `  sockets saw sold out: ${v('viewers_saw_sold_out', 'count')} / ${seed.viewers}`,
    `  spots latency p(95)=${v('spots_latency', 'p(95)').toFixed(1)}ms max=${v('spots_latency', 'max').toFixed(1)}ms`,
    `  out-of-order events: ${v('version_regressions', 'count')}`,
    `  booked=${v('booked', 'count')} sold_out=${v('sold_out', 'count')} (expected ${activity.spots} / ${seed.vusPerActivity - activity.spots})`,
    `  checks rate=${v('checks', 'rate')}`,
  ];
  return {
    stdout: `${lines.join('\n')}\n`,
    [`/load/results/k6-viewers-${seed.runId}.json`]: JSON.stringify(data, null, 2),
  };
}
