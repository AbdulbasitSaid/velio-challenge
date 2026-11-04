import type { SocketLike } from '@/lib/realtime/client';
import { applyVersion, RealtimeClient } from '@/lib/realtime/client';

const A = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
const P = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e01';

class FakeSocket implements SocketLike {
  readyState = 0;
  sent: unknown[] = [];
  onopen: (() => void) | null = null;
  onmessage: ((event: { data: unknown }) => void) | null = null;
  onclose: (() => void) | null = null;
  onerror: (() => void) | null = null;
  constructor(
    readonly url: string,
    private log: string[],
  ) {}
  send(data: string) {
    this.sent.push(JSON.parse(data));
    this.log.push(`send:${(JSON.parse(data) as { type: string }).type}`);
  }
  close() {
    this.readyState = 3;
    this.onclose?.();
  }
  open() {
    this.readyState = 1;
    this.onopen?.();
  }
  receive(msg: unknown) {
    this.onmessage?.({ data: JSON.stringify(msg) });
  }
  drop() {
    this.readyState = 3;
    this.onclose?.();
  }
}

function setup() {
  const log: string[] = [];
  const sockets: FakeSocket[] = [];
  const rt = new RealtimeClient({
    url: 'ws://x/api/ws',
    random: () => 1,
    createSocket: (url) => {
      const s = new FakeSocket(url, log);
      sockets.push(s);
      return s;
    },
  });
  const refresh = vi.fn(() => void log.push('refresh'));
  const onSpots = vi.fn();
  const onPlan = vi.fn();
  const stop = rt.watch({ topics: [`activity:${A}`, `plan:${P}`], refresh, onSpots, onPlan });
  return { rt, log, sockets, refresh, onSpots, onPlan, stop };
}

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

test('rule 1: subscribe is sent before the snapshot fetch', () => {
  const { sockets, log } = setup();
  expect(sockets[0]!.url).toBe('ws://x/api/ws?platform=web');
  sockets[0]!.open();
  expect(log).toEqual(['send:subscribe', 'refresh']);
  expect(sockets[0]!.sent[0]).toEqual({ type: 'subscribe', topics: [`activity:${A}`, `plan:${P}`] });
});

test('spots and plan events reach the watcher; other topics do not', () => {
  const { sockets, onSpots, onPlan } = setup();
  sockets[0]!.open();
  const spots = { type: 'spots', activityId: A, spotsLeft: 3, version: 7, committedAt: 'now' };
  sockets[0]!.receive(spots);
  sockets[0]!.receive({ ...spots, activityId: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e99' });
  sockets[0]!.receive({ type: 'plan', planId: P });
  sockets[0]!.receive({ type: 'nonsense' });
  expect(onSpots).toHaveBeenCalledTimes(1);
  expect(onSpots).toHaveBeenCalledWith(spots);
  expect(onPlan).toHaveBeenCalledWith(P);
});

test('rule 4: resync refetches every snapshot', () => {
  const { sockets, refresh } = setup();
  sockets[0]!.open();
  refresh.mockClear();
  sockets[0]!.receive({ type: 'resync' });
  expect(refresh).toHaveBeenCalledTimes(1);
});

test('rule 3: while disconnected, poll every 10 s and reconnect with resume=1 and backoff', () => {
  const { rt, sockets, refresh } = setup();
  const statuses: string[] = [];
  rt.onStatus((s) => statuses.push(s));
  sockets[0]!.open();
  refresh.mockClear();
  sockets[0]!.drop();
  expect(rt.status).toBe('reconnecting');
  expect(refresh).toHaveBeenCalledTimes(1); // immediate poll
  vi.advanceTimersByTime(1_000); // first backoff (1 s with random = 1)
  expect(sockets[1]!.url).toBe('ws://x/api/ws?platform=web&resume=1');
  sockets[1]!.drop(); // still down: next backoff doubles
  vi.advanceTimersByTime(1_999);
  expect(sockets).toHaveLength(2);
  vi.advanceTimersByTime(1);
  expect(sockets).toHaveLength(3);
  vi.advanceTimersByTime(10_000);
  expect(refresh.mock.calls.length).toBeGreaterThanOrEqual(2); // polling continues
  sockets[sockets.length - 1]!.open();
  expect(rt.status).toBe('live');
  const after = refresh.mock.calls.length;
  vi.advanceTimersByTime(30_000);
  expect(refresh.mock.calls.length).toBe(after); // polling stopped
  expect(statuses).toEqual(['live', 'reconnecting', 'live']);
});

test('backoff is capped at 30 s', () => {
  const { sockets } = setup();
  for (let i = 0; i < 8; i++) {
    sockets[sockets.length - 1]!.drop();
    vi.advanceTimersByTime(30_000);
  }
  const n = sockets.length;
  sockets[n - 1]!.drop();
  vi.advanceTimersByTime(30_000);
  expect(sockets.length).toBe(n + 1);
});

test('rule 6: rendered only on an open socket', () => {
  const { rt, sockets } = setup();
  rt.rendered(A, 7);
  expect(sockets[0]!.sent).toEqual([]);
  sockets[0]!.open();
  rt.rendered(A, 7);
  expect(sockets[0]!.sent.at(-1)).toEqual({ type: 'rendered', activityId: A, version: 7 });
});

test('stopping the last watch closes the socket and stops polling', () => {
  const { sockets, stop, refresh } = setup();
  sockets[0]!.open();
  stop();
  expect(sockets[0]!.sent.at(-1)).toEqual({ type: 'unsubscribe', topics: [`activity:${A}`, `plan:${P}`] });
  expect(sockets[0]!.readyState).toBe(3);
  refresh.mockClear();
  vi.advanceTimersByTime(60_000);
  expect(refresh).not.toHaveBeenCalled();
  expect(sockets).toHaveLength(1);
});

test('a hidden tab closes the socket after 60 s and resumes when visible', () => {
  const { rt, sockets, log } = setup();
  sockets[0]!.open();
  rt.setVisible(false);
  vi.advanceTimersByTime(60_000);
  expect(sockets[0]!.readyState).toBe(3);
  expect(sockets).toHaveLength(1); // no reconnect while hidden
  rt.setVisible(true);
  expect(sockets).toHaveLength(2);
  log.length = 0;
  sockets[1]!.open();
  expect(log).toEqual(['send:subscribe', 'refresh']);
});

test('rule 2: version gate', () => {
  const shown = { spotsLeft: 3, version: 7 };
  expect(applyVersion(shown, { spotsLeft: 5, version: 6 })).toBe(shown);
  expect(applyVersion(shown, { spotsLeft: 5, version: 7 })).toBe(shown);
  expect(applyVersion(shown, { spotsLeft: 2, version: 8 })).toEqual({ spotsLeft: 2, version: 8 });
  expect(applyVersion(null, shown)).toBe(shown);
});
