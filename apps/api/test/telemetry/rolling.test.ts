// S8 FR-009: the admin page's realtime p95 window.
import { expect, test } from 'bun:test';
import { createRollingWindow } from '../../src/telemetry/rolling';

test('nearest-rank p95 over the window; old samples age out; the ring keeps the newest', () => {
  let now = 0;
  const w = createRollingWindow(1_000, 100, () => now);
  expect(w.quantile(0.95)).toEqual({ value: null, count: 0 });
  for (let i = 1; i <= 100; i++) w.record(i / 100);
  expect(w.quantile(0.95)).toEqual({ value: 0.95, count: 100 });
  now = 2_000;
  w.record(3);
  expect(w.quantile(0.95)).toEqual({ value: 3, count: 1 });
});
