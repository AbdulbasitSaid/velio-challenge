import { act, fireEvent, render, screen } from '@testing-library/react';
import type { CommunityPage, PlanView, PublicActivity } from '@velio/contracts';
import { ApiRequestError } from '@/lib/api/client';
import { bookingOutcome } from '@/lib/booking';
import { RealtimeClient, type Watch } from '@/lib/realtime/client';
import { RealtimeProvider } from '@/lib/realtime/react';
import { ActivityLive } from '@/components/activity/activity-live';
import { CommunityLive } from '@/components/community/community-live';
import { Welcome } from '@/components/plan/welcome';
import { ID, inviteView } from './fixtures';

const router = { push: vi.fn(), replace: vi.fn(), refresh: vi.fn() };
vi.mock('next/navigation', () => ({ useRouter: () => router }));
vi.mock('@/components/maps-live', () => ({
  ExploreMap: () => null,
  CommunityMapLive: ({ points }: { points: { title: string; label: string }[] }) => (
    <div data-testid="community-map">{points.map((p) => `${p.title}: ${p.label}`).join('; ')}</div>
  ),
}));

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

const PLAN = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e01';
const activity = (over: Partial<PublicActivity> = {}): PublicActivity => ({
  ...inviteView().activity,
  ...over,
});
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status });
const envelope = (code: string, status: number) =>
  json({ error: { code, message: code, requestId: 'r1' } }, status);

function renderWith(ui: React.ReactNode) {
  const rt = new StubClient();
  render(<RealtimeProvider client={rt}>{ui}</RealtimeProvider>);
  return rt;
}

function setupFetch(book: () => Response) {
  const fetch = vi.fn(async (url: string, _init?: RequestInit) => {
    if (String(url).endsWith('/bookings')) return book();
    if (String(url).includes('next-steps')) return json({ hostOtherDates: [], moreInCommunity: [] });
    return json(activity());
  });
  vi.stubGlobal('fetch', fetch);
  return fetch;
}
const bookingCalls = (fetch: ReturnType<typeof setupFetch>) =>
  fetch.mock.calls.filter(([url]) => String(url).endsWith('/bookings'));
const keyOf = (call: unknown[]) => new Headers((call[1] as RequestInit).headers).get('idempotency-key');

beforeEach(() => {
  sessionStorage.clear();
  router.push.mockReset();
  router.refresh.mockReset();
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('booking outcome mapping (V-BK-3)', () => {
  test.each([
    ['sold_out', 'sold-out'],
    ['activity_started', 'started'],
    ['bookings_paused', 'paused'],
    ['already_booked', 'refresh'],
    ['booking_removed', 'refresh'],
    ['forbidden', 'refresh'],
    ['unauthenticated', 'signin'],
    ['idempotency_conflict', 'error'],
    ['internal', 'error'],
    ['network', 'error'],
  ] as const)('%s → %s', (code, kind) => {
    expect(bookingOutcome(new ApiRequestError(409, code, code)).kind).toBe(kind);
  });
  test('anything that is not an API error is a server error', () => {
    expect(bookingOutcome(new Error('x')).kind).toBe('error');
  });
});

describe('B1 booking (V-BK-3, V-BK-4 unit)', () => {
  test('Booking… at once; success only on the API answer, then B2', async () => {
    let resolve!: (r: Response) => void;
    const fetch = setupFetch(() => undefined as never);
    fetch.mockImplementationOnce(
      (async () => new Promise<Response>((r) => (resolve = r))) as unknown as typeof globalThis.fetch,
    );
    renderWith(<ActivityLive activity={activity()} signedIn initialNextSteps={null} />);
    fireEvent.click(screen.getByRole('button', { name: 'Book a spot' }));
    expect(screen.getByRole('button', { name: 'Booking…' })).toBeDisabled();
    expect(router.push).not.toHaveBeenCalled();
    await act(async () => {}); // the request goes out after the headers resolve
    await act(async () =>
      resolve(
        json(
          {
            booking: {
              id: ID,
              ref: 'VLO-3HX7M',
              activityId: ID,
              planId: PLAN,
              source: 'direct',
              status: 'confirmed',
              createdAt: '2026-11-04T10:00:00Z',
            },
            activity: { id: ID, spotsLeft: 5, version: 4 },
          },
          201,
        ),
      ),
    );
    expect(router.push).toHaveBeenCalledWith(`/plans/${PLAN}?welcome=1`);
    const [, init] = fetch.mock.calls[0]!;
    expect(init?.method).toBe('POST');
    expect(sessionStorage.length).toBe(0); // the key is cleared after a final outcome
  });

  test('a server error offers Try again with the same key', async () => {
    const fetch = setupFetch(() => envelope('internal', 500));
    renderWith(<ActivityLive activity={activity()} signedIn initialNextSteps={null} />);
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Book a spot' })));
    expect(screen.getByText('We couldn’t confirm your spot. Nothing was booked.')).toBeInTheDocument();
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Try again' })));
    const calls = bookingCalls(fetch);
    expect(calls).toHaveLength(2);
    expect(keyOf(calls[0]!)).toBeTruthy();
    expect(keyOf(calls[1]!)).toBe(keyOf(calls[0]!));
  });

  test('sold out mid-checkout: banner and next steps, no Book button', async () => {
    const fetch = setupFetch(() => envelope('sold_out', 409));
    renderWith(<ActivityLive activity={activity()} signedIn initialNextSteps={null} />);
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Book a spot' })));
    expect(screen.getByText('Someone just took the last spot.')).toBeInTheDocument();
    expect(screen.getByText('We didn’t book or charge you.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Book a spot|Try again/ })).toBeNull();
    expect(fetch.mock.calls.some(([url]) => String(url).includes('next-steps'))).toBe(true);
  });

  test('already booked from another tab refreshes the server view', async () => {
    setupFetch(() => envelope('already_booked', 409));
    renderWith(<ActivityLive activity={activity()} signedIn initialNextSteps={null} />);
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Book a spot' })));
    expect(router.refresh).toHaveBeenCalled();
  });

  test('live sold out disables booking; a freed spot brings it back', () => {
    setupFetch(() => json({}));
    const rt = renderWith(<ActivityLive activity={activity()} signedIn initialNextSteps={null} />);
    act(() =>
      rt.seen[0]!.onSpots!({ type: 'spots', activityId: ID, spotsLeft: 0, version: 4, committedAt: 'x' }),
    );
    expect(screen.getByRole('button', { name: 'Sold out' })).toBeDisabled();
    act(() =>
      rt.seen[0]!.onSpots!({ type: 'spots', activityId: ID, spotsLeft: 2, version: 5, committedAt: 'x' }),
    );
    expect(screen.getByRole('button', { name: 'Book a spot' })).toBeEnabled();
    expect(screen.getAllByText('Last 2 spots').length).toBeGreaterThan(0);
  });

  test('a live spots change refetches who is going (T16 D1)', async () => {
    vi.spyOn(Math, 'random').mockReturnValue(0);
    const base = activity();
    const fetch = setupFetch(() => json({}));
    fetch.mockImplementation(async (url: string) =>
      String(url).includes('next-steps')
        ? json({ hostOtherDates: [], moreInCommunity: [] })
        : json({
            ...base,
            spotsLeft: 0,
            version: 4,
            members: { count: 1, preview: [{ ...base.host, shortName: 'Zainab K.' }] },
          }),
    );
    const rt = renderWith(
      <ActivityLive
        activity={{ ...base, members: { count: 0, preview: [] } }}
        signedIn
        initialNextSteps={null}
      />,
    );
    expect(screen.getByText('Be the first to book')).toBeInTheDocument();
    await act(async () => {
      rt.seen[0]!.onSpots!({ type: 'spots', activityId: ID, spotsLeft: 0, version: 4, committedAt: 'x' });
      await new Promise((r) => setTimeout(r, 10));
    });
    expect(fetch.mock.calls.some(([url]) => String(url).endsWith(`/activities/${ID}`))).toBe(true);
    expect(screen.queryByText('Be the first to book')).toBeNull();
    expect(screen.getByText('Zainab K. is going')).toBeInTheDocument();
  });

  test.each([
    [
      'already booked',
      activity({ viewer: { isHost: false, booking: { id: ID, planId: PLAN, status: 'confirmed' } } }),
      'You’re already going',
    ],
    ['own activity', activity({ viewer: { isHost: true, booking: null } }), 'Open live attendance'],
    ['started', activity({ status: 'started' }), 'This activity has started.'],
    ['paused', activity({ bookingsPaused: true }), 'Bookings are paused for this activity.'],
    [
      'removed',
      activity({ viewer: { isHost: false, booking: { id: ID, planId: PLAN, status: 'removed' } } }),
      'The host removed your booking for this activity.',
    ],
  ])('%s', (_name, a, text) => {
    setupFetch(() => json({}));
    renderWith(<ActivityLive activity={a} signedIn initialNextSteps={null} />);
    expect(screen.getByText(text)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Book a spot' })).toBeNull();
  });

  test('started names the closing time in the activity’s zone', () => {
    setupFetch(() => json({}));
    renderWith(<ActivityLive activity={activity({ status: 'started' })} signedIn initialNextSteps={null} />);
    expect(screen.getByText('Bookings closed at 17:30 Nairobi time.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Bookings closed' })).toBeDisabled();
  });

  test('signed out: Book goes to sign-in and back (V-BK-2 content)', () => {
    setupFetch(() => json({}));
    renderWith(<ActivityLive activity={activity()} signedIn={false} initialNextSteps={null} />);
    expect(screen.getByRole('link', { name: 'Book a spot' })).toHaveAttribute(
      'href',
      `/signin?next=${encodeURIComponent(`/activities/${ID}`)}`,
    );
    expect(screen.getAllByText('Mon 14 Dec, 17:30').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Nairobi time').length).toBeGreaterThan(0);
    expect(screen.getByText('KES 3,500 · pay the host on the day')).toBeInTheDocument();
    expect(screen.getAllByText('Hosted by Amara W.').length).toBeGreaterThan(0);
  });
});

function communityPage(over: Partial<CommunityPage['activities'][number]>[] = [{}]): CommunityPage {
  const a = activity();
  return {
    community: {
      slug: 'explore-kenya',
      name: 'Explore Kenya',
      blurb: 'Lakes and parks.',
      coverPhotoUrl: null,
      upcomingCount: over.length,
    },
    activities: over.map((o, i) => ({
      id: `0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e1${i}`,
      title: a.title,
      startsAt: a.startsAt,
      timezone: a.timezone,
      priceMinor: a.priceMinor,
      currency: a.currency,
      photoUrl: null,
      capacity: a.capacity,
      spotsLeft: a.spotsLeft,
      version: 1,
      status: 'open' as const,
      community: a.community,
      location: { venueName: 'Boat Club', lat: -0.7, lng: 36.4 },
      members: a.members,
      ...o,
    })),
  };
}

describe('C1 community (V-BK-1 unit)', () => {
  const matchMedia = (wide: boolean) =>
    vi.stubGlobal(
      'matchMedia',
      vi.fn(() => ({ matches: wide, addEventListener: () => {}, removeEventListener: () => {} })),
    );

  test('phone: list first, the map only after choosing Map, without sold-out activities', () => {
    matchMedia(false);
    setupFetch(() => json({}));
    renderWith(
      <CommunityLive
        page={communityPage([{ title: 'Kayaking' }, { title: 'Cycle', spotsLeft: 0, status: 'sold_out' }])}
      />,
    );
    expect(screen.getByText('1 upcoming activity with spots')).toBeInTheDocument();
    expect(screen.getAllByRole('link', { name: /Kayaking/ }).length).toBeGreaterThan(0);
    expect(screen.queryByTestId('community-map')).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Map' }));
    expect(screen.getByTestId('community-map')).toHaveTextContent('Kayaking: 6 left');
    expect(screen.getByTestId('community-map')).not.toHaveTextContent('Cycle');
  });

  test('wide: list and map side by side', () => {
    matchMedia(true);
    setupFetch(() => json({}));
    renderWith(<CommunityLive page={communityPage()} />);
    expect(screen.getByTestId('community-map')).toBeInTheDocument();
  });

  test('a live sold out takes the activity off the map', () => {
    matchMedia(true);
    setupFetch(() => json({}));
    const page = communityPage();
    const rt = renderWith(<CommunityLive page={page} />);
    const id = page.activities[0]!.id;
    act(() =>
      rt.seen[0]!.onSpots!({ type: 'spots', activityId: id, spotsLeft: 0, version: 2, committedAt: 'x' }),
    );
    expect(screen.getByTestId('community-map')).toHaveTextContent('');
    expect(screen.getByText('No upcoming activities with spots')).toBeInTheDocument();
  });

  test('empty community', () => {
    matchMedia(false);
    setupFetch(() => json({}));
    renderWith(<CommunityLive page={communityPage([])} />);
    expect(screen.getByText('Nothing coming up right now')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Map' })).toBeNull();
  });
});

describe('B2 invite prompt (V-BK-5 unit)', () => {
  const plan = (canInvite = true): PlanView => ({
    id: PLAN,
    activity: {
      id: ID,
      title: 'Sunset Kayaking',
      startsAt: '2026-12-14T14:30:00Z',
      timezone: 'Africa/Nairobi',
    },
    owner: { id: ID, displayName: 'Tunde Adeyemi', shortName: 'Tunde A.', avatarSeed: ID },
    members: [],
    viewer: { booking: { id: ID, ref: 'VLO-3HX7M', status: 'confirmed' }, canInvite },
    invites: [],
  });

  test('invite step first, then drops ?welcome=1 so it is shown once', () => {
    setupFetch(() => json({}));
    const replace = vi.spyOn(window.history, 'replaceState');
    renderWith(<Welcome plan={plan()} spots={{ spotsLeft: 5, version: 3 }} />);
    expect(screen.getByText('Mon 14 Dec, 17:30 Nairobi time · VLO-3HX7M')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Who’s coming with you?' })).toBeInTheDocument();
    expect(
      screen.getByText('Only 5 spots left. Invites don’t hold a spot, so tell friends now.'),
    ).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Vouch for a friend/ })).toHaveAttribute(
      'href',
      `/plans/${PLAN}?invite=vouch`,
    );
    expect(screen.getByRole('link', { name: /Share a link/ })).toHaveAttribute(
      'href',
      `/plans/${PLAN}?invite=public`,
    );
    expect(screen.getByRole('link', { name: 'Go to my plan' })).toHaveAttribute('href', `/plans/${PLAN}`);
    expect(replace.mock.calls.at(-1)?.[2]).toBe(`/plans/${PLAN}`);
  });

  test('without invites (holdout) only the confirmation and the plan link show', () => {
    setupFetch(() => json({}));
    renderWith(<Welcome plan={plan(false)} spots={{ spotsLeft: 5, version: 3 }} />);
    expect(screen.queryByRole('link', { name: /Vouch for a friend/ })).toBeNull();
    expect(screen.getByRole('link', { name: 'Go to my plan' })).toBeInTheDocument();
  });
});
