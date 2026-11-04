import { act, render, screen } from '@testing-library/react';
import { RealtimeClient, type Watch } from '@/lib/realtime/client';
import { RealtimeProvider } from '@/lib/realtime/react';
import { InviteLive } from '@/components/invite/invite-live';
import { inviteView } from './fixtures';

class StubClient extends RealtimeClient {
  seen: Watch[] = [];
  constructor() {
    super({ url: 'ws://x' });
  }
  override watch(w: Watch) {
    this.seen.push(w);
    return () => undefined;
  }
  override rendered() {}
}

function setup(view = inviteView()) {
  const fetch = vi.fn(async (url: string) =>
    String(url).includes('next-steps')
      ? new Response(JSON.stringify({ hostOtherDates: [], moreInCommunity: [] }), { status: 200 })
      : new Response(null, { status: 204 }),
  );
  vi.stubGlobal('fetch', fetch);
  const rt = new StubClient();
  render(
    <RealtimeProvider client={rt}>
      <InviteLive view={view} initialNextSteps={null} />
    </RealtimeProvider>,
  );
  return { rt, fetch };
}

beforeEach(() => vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'setTimeout', 'Date'] }));
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

const opens = (fetch: ReturnType<typeof vi.fn>) =>
  fetch.mock.calls.filter(([url]) => String(url).endsWith('/opens'));

test('the open beacon fires once, after paint (V-OPEN-1)', async () => {
  const { fetch } = setup();
  expect(opens(fetch)).toHaveLength(0); // nothing during render
  await act(async () => void (await vi.advanceTimersByTimeAsync(50)));
  expect(opens(fetch)).toHaveLength(1);
  const [, init] = opens(fetch)[0] as unknown as [string, RequestInit];
  expect(init.method).toBe('POST');
  expect(init.body).toBe('{"platform":"web"}');
  await act(async () => void (await vi.advanceTimersByTimeAsync(1000)));
  expect(opens(fetch)).toHaveLength(1);
});

test('G1 vouch shows the inviter lead and claim; live sold out switches to G5 and back (V-RT-1 unit)', async () => {
  const { rt } = setup(inviteView({ note: 'Sunset on the lake.' }));
  expect(screen.getByText('wants you on')).toBeInTheDocument();
  expect(screen.getByText('“Sunset on the lake.”', { exact: false })).toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Claim my spot' })).toHaveAttribute('href', '/i/K7PQ2N/claim');
  const activityId = inviteView().activity.id;
  act(() => rt.seen[0]!.onSpots!({ type: 'spots', activityId, spotsLeft: 0, version: 4, committedAt: 'x' }));
  expect(
    screen.getByRole('heading', { name: 'This one filled up before you got here.' }),
  ).toBeInTheDocument();
  expect(screen.getByText('Tell Tunde')).toBeInTheDocument();
  act(() => rt.seen[0]!.onSpots!({ type: 'spots', activityId, spotsLeft: 1, version: 5, committedAt: 'x' }));
  expect(screen.getByRole('link', { name: 'Claim my spot' })).toBeInTheDocument();
  expect(screen.getByText('Last spot')).toBeInTheDocument();
});

test('offline disables claiming; nothing is queued', () => {
  vi.spyOn(navigator, 'onLine', 'get').mockReturnValue(false);
  setup(inviteView({ rail: 'public' }));
  expect(screen.getByRole('button', { name: 'Reconnect to claim' })).toBeDisabled();
  expect(screen.queryByRole('link', { name: 'Claim my spot' })).toBeNull();
  expect(screen.getByText('Join the group going to')).toBeInTheDocument();
});

test('G5 reached live renders the next steps it fetches', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (url: string) =>
      String(url).includes('next-steps')
        ? new Response(
            JSON.stringify({
              hostOtherDates: [],
              moreInCommunity: [
                {
                  ...inviteView().activity,
                  id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e09',
                  title: 'Karura cycle',
                  location: { venueName: 'Karura', lat: 0, lng: 0 },
                },
              ],
            }),
            { status: 200 },
          )
        : new Response(null, { status: 204 }),
    ),
  );
  const rt = new StubClient();
  render(
    <RealtimeProvider client={rt}>
      <InviteLive view={inviteView()} initialNextSteps={null} />
    </RealtimeProvider>,
  );
  const activityId = inviteView().activity.id;
  act(() => rt.seen[0]!.onSpots!({ type: 'spots', activityId, spotsLeft: 0, version: 4, committedAt: 'x' }));
  await act(async () => void (await vi.advanceTimersByTimeAsync(10)));
  expect(screen.getByText('More in Explore Kenya')).toBeInTheDocument();
  expect(screen.getByText('Karura cycle')).toBeInTheDocument();
});

test('a live spots change refetches who is going (S6 D3)', async () => {
  vi.spyOn(Math, 'random').mockReturnValue(0);
  const base = inviteView();
  const a = base.activity;
  const fetch = vi.fn(async (url: string) =>
    String(url).endsWith(`/activities/${a.id}`)
      ? new Response(
          JSON.stringify({
            ...a,
            spotsLeft: a.spotsLeft - 1,
            version: a.version + 1,
            members: { count: 1, preview: [{ ...a.host, shortName: 'Zainab K.' }] },
          }),
          { status: 200 },
        )
      : new Response(null, { status: 204 }),
  );
  vi.stubGlobal('fetch', fetch);
  const rt = new StubClient();
  render(
    <RealtimeProvider client={rt}>
      <InviteLive
        view={{ ...base, activity: { ...a, members: { count: 0, preview: [] } } }}
        initialNextSteps={null}
      />
    </RealtimeProvider>,
  );
  expect(screen.getByText('Be the first to book')).toBeInTheDocument();
  act(() =>
    rt.seen[0]!.onSpots!({
      type: 'spots',
      activityId: a.id,
      spotsLeft: a.spotsLeft - 1,
      version: a.version + 1,
      committedAt: 'x',
    }),
  );
  await act(async () => void (await vi.advanceTimersByTimeAsync(10)));
  expect(screen.queryByText('Be the first to book')).toBeNull();
  expect(screen.getByText('Zainab K. is going')).toBeInTheDocument();
});
