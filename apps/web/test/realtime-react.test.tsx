import { act, render, screen } from '@testing-library/react';
import type { SpotsEvent } from '@velio/contracts';
import { RealtimeClient, type Watch } from '@/lib/realtime/client';
import { RealtimeProvider, useLiveSpots } from '@/lib/realtime/react';

const A = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';

class StubClient extends RealtimeClient {
  seen: Watch[] = [];
  acks: [string, number][] = [];
  constructor() {
    super({ url: 'ws://x' });
  }
  override watch(w: Watch) {
    this.seen.push(w);
    return () => undefined;
  }
  override rendered(activityId: string, version: number) {
    this.acks.push([activityId, version]);
  }
  emit(spotsLeft: number, version: number) {
    const e: SpotsEvent = { type: 'spots', activityId: A, spotsLeft, version, committedAt: 'x' };
    act(() => this.seen[0]!.onSpots!(e));
  }
}

function Badge() {
  const { spots } = useLiveSpots({ [A]: { spotsLeft: 5, version: 10 } }, async () => ({}), { announce: [A] });
  const s = spots[A]!;
  return <span data-testid="badge">{`${s.spotsLeft}@${s.version}${s.changed ? ' changed' : ''}`}</span>;
}

beforeEach(() =>
  vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'Date', 'requestAnimationFrame'] }),
);
afterEach(() => vi.useRealTimers());

test('events pass the version gate, are acknowledged after paint, and announcements are throttled', () => {
  const rt = new StubClient();
  render(
    <RealtimeProvider client={rt}>
      <Badge />
    </RealtimeProvider>,
  );
  expect(rt.seen[0]!.topics).toEqual([`activity:${A}`]);
  const badge = screen.getByTestId('badge');
  const region = screen.getByRole('status');

  rt.emit(4, 11);
  expect(badge).toHaveTextContent('4@11 changed');
  expect(region).toHaveTextContent('4 spots left');
  act(() => void vi.advanceTimersByTime(20));
  expect(rt.acks).toEqual([[A, 11]]);

  rt.emit(9, 9); // older version: ignored, not acknowledged
  expect(badge).toHaveTextContent('4@11');

  rt.emit(3, 12);
  rt.emit(1, 13);
  expect(badge).toHaveTextContent('1@13');
  expect(region).toHaveTextContent('4 spots left'); // within 5 s: held back
  act(() => void vi.advanceTimersByTime(5_000));
  expect(region).toHaveTextContent('Last spot'); // only the latest is read out
});
