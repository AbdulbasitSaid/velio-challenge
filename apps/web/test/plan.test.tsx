import { act, fireEvent, render, screen, within } from '@testing-library/react';
import type { Invite, MyPlans as MyPlansData, PlanView, PublicActivity } from '@velio/contracts';
import { ApiRequestError } from '@/lib/api/client';
import { RealtimeClient, type Watch } from '@/lib/realtime/client';
import { RealtimeProvider } from '@/lib/realtime/react';
import { parseRole, roleFor } from '@/lib/role';
import { displayLink, smsHref, vouchMessage } from '@/lib/share';
import { MyPlans } from '@/components/plan/my-plans';
import { PlanLive } from '@/components/plan/plan-live';
import { ShareLink } from '@/components/plan/share-link';
import { noHoldLine, Vouch, vouchFailure } from '@/components/plan/vouch';
import { whatsappHref } from '@/components/invite/parts';
import { ID, inviteView } from './fixtures';

const router = { push: vi.fn(), replace: vi.fn(), refresh: vi.fn() };
vi.mock('next/navigation', () => ({ useRouter: () => router }));
vi.mock('@/components/maps-live', () => ({ ExploreMap: () => null }));

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
const ME = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e02';
const ZAINAB = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e03';
const KOFI = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e04';
const LINK = 'https://d3x9k2.cloudfront.net/i/H4XM9R';

const member = (id: string, displayName: string) => ({
  id,
  displayName,
  shortName: `${displayName.split(' ')[0]} ${displayName.split(' ')[1]![0]}.`,
  avatarSeed: id,
});
const tunde = member(ME, 'Tunde Adeyemi');
const zainab = member(ZAINAB, 'Zainab Okafor');

const activity = (over: Partial<PublicActivity> = {}): PublicActivity => ({
  ...inviteView().activity,
  ...over,
});

function planView(over: Partial<PlanView> = {}): PlanView {
  return {
    id: PLAN,
    activity: {
      id: ID,
      title: 'Sunset Kayaking',
      startsAt: '2026-12-14T14:30:00Z',
      timezone: 'Africa/Nairobi',
    },
    owner: tunde,
    members: [
      { person: tunde, source: 'direct', invitedBy: null, joinedAt: '2026-12-02T08:00:00Z' },
      { person: zainab, source: 'vouch', invitedBy: tunde, joinedAt: '2026-12-03T08:00:00Z' },
      {
        person: member(KOFI, 'Kofi Mensah'),
        source: 'public',
        invitedBy: tunde,
        joinedAt: '2026-12-04T08:00:00Z',
      },
    ],
    viewer: { booking: { id: ID, ref: 'VLO-3HX7M', status: 'confirmed' }, canInvite: true },
    invites: [
      {
        id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e10',
        rail: 'vouch',
        inviteeName: 'Wanjiru Njoroge',
        createdBy: tunde,
        status: 'created',
        opens: 0,
        claims: 0,
        paused: false,
        pausedReason: null,
        createdAt: '2026-12-04T08:00:00Z',
        code: 'H4XM9R',
        link: LINK,
        note: null,
      },
      {
        id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e11',
        rail: 'public',
        inviteeName: null,
        createdBy: zainab,
        status: 'claimed',
        opens: 3,
        claims: 1,
        paused: false,
        pausedReason: null,
        createdAt: '2026-12-03T08:00:00Z',
      },
    ],
    ...over,
  };
}

function invite(over: Partial<Invite> = {}): Invite {
  return {
    id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e10',
    code: 'H4XM9R',
    link: LINK,
    rail: 'vouch',
    inviteeName: 'Wanjiru Njoroge',
    note: null,
    status: 'created',
    opens: 0,
    claims: 0,
    paused: false,
    pausedReason: null,
    createdBy: tunde,
    createdAt: '2026-12-04T08:00:00Z',
    ...over,
  };
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status });
const envelope = (code: string, status: number) =>
  json({ error: { code, message: code, requestId: 'r1' } }, status);

function renderWith(ui: React.ReactNode) {
  const rt = new StubClient();
  render(<RealtimeProvider client={rt}>{ui}</RealtimeProvider>);
  return rt;
}

function stubFetch(handler: (url: string, init?: RequestInit) => Response | Promise<Response>) {
  const fetch = vi.fn(async (url: string, init?: RequestInit) => handler(String(url), init));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

beforeEach(() => {
  router.push.mockReset();
  router.refresh.mockReset();
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('share URLs (V-INV-1)', () => {
  const message = vouchMessage('Wanjiru Njoroge', planView().activity, LINK);

  test('vouch.message names the friend, the activity and its day, and carries the link', () => {
    expect(message).toBe(
      'Wanjiru, I’m going to Sunset Kayaking on Mon 14 Dec and want you there. Claim your spot: ' + LINK,
    );
  });

  test('WhatsApp and SMS carry only the message, never a recipient', () => {
    expect(whatsappHref(message)).toBe(`https://wa.me/?text=${encodeURIComponent(message)}`);
    expect(smsHref(message)).toBe(`sms:?&body=${encodeURIComponent(message)}`);
  });

  test('the link reads without its scheme', () => {
    expect(displayLink(LINK)).toBe('d3x9k2.cloudfront.net/i/H4XM9R');
  });

  test('no-hold line follows the live count', () => {
    expect(noHoldLine(5)).toBe('Invites don’t hold a spot. 5 spots left right now.');
    expect(noHoldLine(1)).toBe('Invites don’t hold a spot. 1 spot left right now.');
  });
});

describe('B3 vouch (V-INV-1)', () => {
  test('the name is required', async () => {
    const fetch = stubFetch(() => json(activity()));
    renderWith(<Vouch plan={planView()} activity={activity()} />);
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Create invite' })));
    expect(screen.getByText('Add their name, so the invite is addressed to them.')).toBeInTheDocument();
    expect(fetch.mock.calls.filter(([u]) => String(u).endsWith('/invites'))).toHaveLength(0);
  });

  test('creates with the contact in the body only, then offers the send links', async () => {
    const fetch = stubFetch((url) => (url.endsWith('/invites') ? json(invite(), 201) : json(activity())));
    renderWith(<Vouch plan={planView()} activity={activity()} />);
    fireEvent.change(screen.getByLabelText('Friend’s name'), { target: { value: 'Wanjiru Njoroge' } });
    fireEvent.change(screen.getByLabelText('Their phone or email'), {
      target: { value: '+254 722 118 904' },
    });
    fireEvent.change(screen.getByLabelText('Note (optional)'), { target: { value: 'Sunset on the lake' } });
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Create invite' })));

    const [url, init] = fetch.mock.calls.find(([u]) => String(u).endsWith('/invites'))!;
    expect(url).toBe(`/api/plans/${PLAN}/invites`);
    expect(JSON.parse(String(init!.body))).toEqual({
      rail: 'vouch',
      inviteeName: 'Wanjiru Njoroge',
      contact: '+254 722 118 904',
      note: 'Sunset on the lake',
    });

    expect(screen.getByRole('heading', { name: 'Send it to Wanjiru' })).toBeInTheDocument();
    expect(screen.getByText('Code H4XM9R')).toBeInTheDocument();
    const hrefs = screen.getAllByRole('link').map((a) => a.getAttribute('href') ?? '');
    const wa = hrefs.find((h) => h.startsWith('https://wa.me/'))!;
    const sms = hrefs.find((h) => h.startsWith('sms:'))!;
    for (const h of [wa, sms]) {
      expect(decodeURIComponent(h)).toContain(LINK);
      expect(decodeURIComponent(h)).not.toContain('722');
    }
  });

  test('an invalid contact is shown on the field', async () => {
    stubFetch((url) => (url.endsWith('/invites') ? envelope('invalid_contact', 400) : json(activity())));
    renderWith(<Vouch plan={planView()} activity={activity()} />);
    fireEvent.change(screen.getByLabelText('Friend’s name'), { target: { value: 'Wanjiru' } });
    fireEvent.change(screen.getByLabelText('Their phone or email'), { target: { value: '0722' } });
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Create invite' })));
    expect(
      screen.getByText('Enter a full phone number with country code, or an email address.'),
    ).toBeInTheDocument();
  });

  test.each([
    ['invalid_contact', 'field'],
    ['validation_failed', 'field'],
    ['activity_started', 'banner'],
    ['forbidden', 'banner'],
    ['internal', 'banner'],
  ] as const)('%s → %s', (code, kind) => {
    expect(kind in vouchFailure(new ApiRequestError(400, code, code))).toBe(true);
  });
});

describe('B3b public link (V-INV-2)', () => {
  test('gets the caller’s link and copies it', async () => {
    const writeText = vi.fn(async () => undefined);
    vi.stubGlobal('navigator', { ...navigator, clipboard: { writeText } });
    const fetch = stubFetch(() => json(invite({ rail: 'public', inviteeName: null, code: 'P8KT4W' })));
    renderWith(<ShareLink plan={planView()} activity={activity()} />);
    await act(async () => {});
    expect(JSON.parse(String(fetch.mock.calls[0]![1]!.body))).toEqual({ rail: 'public' });
    expect(screen.getByText(displayLink(LINK))).toBeInTheDocument();
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Copy link' })));
    expect(writeText).toHaveBeenCalledWith(LINK);
    expect(screen.getByText('Link copied')).toBeInTheDocument();
  });

  test('auto-paused: the reason, and resume for the creator', async () => {
    let paused = true;
    const fetch = stubFetch((url, init) => {
      if (init?.method === 'DELETE') {
        paused = false;
        return new Response(null, { status: 204 });
      }
      return json(invite({ rail: 'public', paused, pausedReason: paused ? 'auto' : null }));
    });
    renderWith(<ShareLink plan={planView()} activity={activity()} />);
    await act(async () => {});
    expect(screen.getByText('This link is paused.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Copy link' })).toBeNull();
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Resume link' })));
    expect(
      fetch.mock.calls.some(([u, i]) => String(u) === '/api/invites/H4XM9R/pause' && i?.method === 'DELETE'),
    ).toBe(true);
    expect(screen.queryByText('This link is paused.')).toBeNull();
    expect(screen.getByRole('button', { name: 'Copy link' })).toBeInTheDocument();
  });

  test('paused by the host: no resume', async () => {
    stubFetch(() => json(invite({ rail: 'public', paused: true, pausedReason: 'host' })));
    renderWith(<ShareLink plan={planView()} activity={activity()} />);
    await act(async () => {});
    expect(screen.getByText('The host paused this link.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Link paused' })).toBeDisabled();
  });
});

describe('B4 Plan (V-PLAN-1)', () => {
  test('members with full names and how each joined; invites with status', () => {
    stubFetch(() => json(activity()));
    renderWith(<PlanLive plan={planView()} activity={activity()} viewerId={ME} nextSteps={null} />);
    expect(screen.getByText('3 people')).toBeInTheDocument();
    expect(screen.getByText('Tunde Adeyemi (you)')).toBeInTheDocument();
    expect(screen.getByText('Via Tunde')).toBeInTheDocument();
    expect(screen.getAllByText('Public link').length).toBeGreaterThan(0);
    expect(screen.getByText('Invite for Wanjiru')).toBeInTheDocument();
    expect(screen.getByText('Vouch from you · Fri 4 Dec')).toBeInTheDocument();
    expect(screen.getByText('From Zainab · 1 claim')).toBeInTheDocument();
    expect(screen.getAllByText('VLO-3HX7M').length).toBeGreaterThan(0);
    expect(screen.getAllByRole('link', { name: 'Vouch for a friend' })[0]).toHaveAttribute(
      'href',
      `/plans/${PLAN}?invite=vouch`,
    );
  });

  test('a plan event fetches the Plan again, so an invite moves to Opened live', async () => {
    let status: 'created' | 'opened' = 'created';
    stubFetch((url) => {
      if (url.endsWith(`/plans/${PLAN}`)) {
        const p = planView();
        p.invites[0]!.status = status;
        return json(p);
      }
      return json(activity());
    });
    const rt = renderWith(
      <PlanLive plan={planView()} activity={activity()} viewerId={ME} nextSteps={null} />,
    );
    expect(rt.seen[0]!.topics).toEqual([`activity:${ID}`, `plan:${PLAN}`]);
    const row = () => screen.getByText('Invite for Wanjiru').closest('.vl-listrow') as HTMLElement;
    expect(within(row()).getByText('Created')).toBeInTheDocument();
    status = 'opened';
    await act(async () => rt.seen[0]!.onPlan!(PLAN));
    expect(within(row()).getByText('Opened')).toBeInTheDocument();
  });

  test('only me: the invite prompt with the live count', () => {
    stubFetch(() => json(activity()));
    renderWith(
      <PlanLive
        plan={planView({ members: planView().members.slice(0, 1), invites: [] })}
        activity={activity()}
        viewerId={ME}
        nextSteps={null}
      />,
    );
    expect(screen.getByText('1 person')).toBeInTheDocument();
    expect(screen.getByText('Who’s coming with you?')).toBeInTheDocument();
    expect(
      screen.getByText('Only 6 spots left. Invites don’t hold a spot, so tell friends now.'),
    ).toBeInTheDocument();
  });

  test('without canInvite (holdout) there are no invite tools', () => {
    stubFetch(() => json(activity()));
    renderWith(
      <PlanLive
        plan={planView({
          viewer: { booking: { id: ID, ref: 'VLO-3HX7M', status: 'confirmed' }, canInvite: false },
        })}
        activity={activity()}
        viewerId={ME}
        nextSteps={null}
      />,
    );
    expect(screen.queryByRole('link', { name: 'Vouch for a friend' })).toBeNull();
    expect(screen.queryByRole('link', { name: 'Share link' })).toBeNull();
  });

  test('removed by the host: the banner and next steps, no members', () => {
    stubFetch(() => json(activity()));
    renderWith(
      <PlanLive
        plan={planView({
          viewer: { booking: { id: ID, ref: 'VLO-3HX7M', status: 'removed' }, canInvite: false },
        })}
        activity={activity()}
        viewerId={ME}
        nextSteps={{
          hostOtherDates: [{ ...activity(), id: KOFI, location: { venueName: 'Boat Club', lat: 0, lng: 0 } }],
          moreInCommunity: [],
        }}
      />,
    );
    expect(screen.getByText('The host removed this booking.')).toBeInTheDocument();
    expect(screen.getByText('Your plan')).toBeInTheDocument();
    expect(screen.getByText('Amara’s other dates')).toBeInTheDocument();
    expect(screen.queryByText('Going')).toBeNull();
    expect(screen.queryByText('VLO-3HX7M')).toBeNull();
  });
});

describe('B6 My plans (V-MY-1)', () => {
  const card = (over: Partial<MyPlansData['upcoming'][number]['activity']> = {}) => ({
    ...activity(),
    location: { venueName: 'Boat Club', lat: 0, lng: 0 },
    ...over,
  });
  const data: MyPlansData = {
    upcoming: [
      {
        planId: PLAN,
        activity: card(),
        booking: { id: ID, ref: 'VLO-3HX7M', status: 'confirmed' },
        members: { count: 4, preview: [tunde, zainab] },
      },
      {
        planId: KOFI,
        activity: card({ id: KOFI, title: 'Medina food walk' }),
        booking: { id: KOFI, ref: 'VLO-7RT2P', status: 'removed' },
        members: { count: 1, preview: [tunde] },
      },
    ],
    past: [
      {
        planId: ZAINAB,
        activity: card({ id: ZAINAB, title: 'Hell’s Gate cycle', startsAt: '2026-10-19T06:00:00Z' }),
        booking: { id: ZAINAB, ref: 'VLO-Q2WD8', status: 'confirmed' },
        members: { count: 2, preview: [tunde, zainab] },
      },
    ],
  };

  test('upcoming with ref and live spots, removed marked; past on its tab', () => {
    stubFetch(() => json(data));
    renderWith(<MyPlans data={data} viewerName="Tunde Adeyemi" />);
    const sunset = screen.getByRole('link', { name: /Sunset Kayaking/ });
    expect(sunset).toHaveAttribute('href', `/plans/${PLAN}`);
    expect(within(sunset).getByText('VLO-3HX7M')).toBeInTheDocument();
    expect(within(sunset).getByText('6 spots left')).toBeInTheDocument();
    expect(
      within(screen.getByRole('link', { name: /Medina/ })).getByText('Removed by host'),
    ).toBeInTheDocument();
    expect(screen.queryByText('Hell’s Gate cycle')).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Past' }));
    expect(screen.getByText('Hell’s Gate cycle')).toBeInTheDocument();
    expect(screen.queryByText('Sunset Kayaking')).toBeNull();
  });

  test('empty', () => {
    stubFetch(() => json({ upcoming: [], past: [] }));
    renderWith(<MyPlans data={{ upcoming: [], past: [] }} viewerName="Tunde Adeyemi" />);
    expect(screen.getByText('No plans yet')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Browse communities' })).toHaveAttribute('href', '/');
  });

  test('sign out ends the session and leaves', async () => {
    const fetch = stubFetch(() => new Response(null, { status: 204 }));
    renderWith(<MyPlans data={data} viewerName="Tunde Adeyemi" />);
    await act(async () => fireEvent.click(screen.getByRole('button', { name: 'Sign out' })));
    expect(
      fetch.mock.calls.some(([u, i]) => String(u) === '/api/sessions/current' && i?.method === 'DELETE'),
    ).toBe(true);
    expect(router.push).toHaveBeenCalledWith('/');
  });
});

describe('role toggle (FR-011)', () => {
  test('host pages are Host; elsewhere the remembered choice', () => {
    expect(roleFor('/host/activities', 'booker')).toBe('host');
    expect(roleFor('/me/plans', 'host')).toBe('host');
    expect(roleFor('/me/plans', 'booker')).toBe('booker');
    expect(parseRole('host')).toBe('host');
    expect(parseRole('admin')).toBe('booker');
    expect(parseRole(undefined)).toBe('booker');
  });
});
