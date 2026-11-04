import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import type { Attendance, Attendee, PublicActivity } from '@velio/contracts';
import { ApiRequestError } from '@/lib/api/client';
import {
  attendanceStats,
  attendeeSource,
  groupsSummary,
  matchesGuest,
  orderAttendees,
} from '@/lib/attendance';
import { RealtimeClient, type Watch } from '@/lib/realtime/client';
import { RealtimeProvider } from '@/lib/realtime/react';
import { AttendanceLive, markFailure } from '@/components/host/attendance-live';
import { ID, inviteView } from './fixtures';

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

const uuid = (n: number) => `0190a6f2-1f2b-7c3d-8e4f-${String(n).padStart(12, '0')}`;
const person = (n: number, displayName: string) => ({
  id: uuid(n),
  displayName,
  shortName: `${displayName.split(' ')[0]} ${displayName.split(' ')[1]![0]}.`,
  avatarSeed: uuid(n),
});
const TUNDE = person(1, 'Tunde Adeyemi');
const ZAINAB = person(2, 'Zainab Okafor');
const KOFI = person(3, 'Kofi Mensah');
const OMAR = person(4, 'Omar Mahmoud');
const PLAN_T = uuid(101);
const PLAN_O = uuid(102);

function attendee(n: number, over: Partial<Attendee> = {}): Attendee {
  return {
    bookingId: uuid(200 + n),
    ref: `VLO-${['3HX7M', '48213', '9KQ2D', 'C4N8H', 'T6V2K'][n % 5]}`,
    status: 'confirmed',
    person: TUNDE,
    bookedAt: `2026-12-0${n + 1}T08:00:00Z`,
    source: 'direct',
    invitedBy: null,
    planId: PLAN_T,
    mark: null,
    markedAt: null,
    ...over,
  };
}

const ROWS: Attendee[] = [
  attendee(0),
  attendee(1, { person: ZAINAB, source: 'vouch', invitedBy: TUNDE }),
  attendee(2, { person: KOFI, source: 'public', invitedBy: TUNDE }),
  attendee(3, { person: OMAR, planId: PLAN_O }),
];

function attendance(over: Partial<Attendance['activity']> = {}, attendees = ROWS): Attendance {
  return {
    activity: {
      id: ID,
      capacity: 14,
      spotsLeft: 14 - attendees.filter((a) => a.status === 'confirmed').length,
      version: 4,
      startsAt: '2026-12-14T14:30:00Z',
      timezone: 'Africa/Nairobi',
      started: false,
      ...over,
    },
    attendees,
  };
}

const activity = (): PublicActivity => ({
  ...inviteView().activity,
  startsAt: '2026-12-14T14:30:00Z',
  timezone: 'Africa/Nairobi',
});

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
const envelope = (code: string, status: number) =>
  json({ error: { code, message: code, requestId: 'r1' } }, status);

function stubFetch(handler: (url: string, init?: RequestInit) => Response) {
  const fetch = vi.fn(async (url: string, init?: RequestInit) => handler(String(url), init));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function renderLive(data: Attendance) {
  const client = new StubClient();
  render(
    <RealtimeProvider client={client}>
      <AttendanceLive attendance={data} activity={activity()} />
    </RealtimeProvider>,
  );
  return client;
}

const going = () => screen.getByRole('heading', { name: /going|who came/i }).closest('section')!;

beforeEach(() => {
  vi.useFakeTimers({ toFake: ['Date'] });
  vi.setSystemTime(Date.parse('2026-12-10T08:00:00Z'));
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe('attendance helpers', () => {
  it('labels sources as the canvas does', () => {
    expect(ROWS.map(attendeeSource)).toEqual(['Direct', 'Via Tunde', 'Public link', 'Direct']);
  });

  it('groups confirmed bookings by Plan, named after the first booking', () => {
    const removed = attendee(4, { person: person(5, 'Lerato Nkosi'), planId: PLAN_O, status: 'removed' });
    const solo = attendee(5, { person: person(6, 'Yusuf Bello'), planId: uuid(103) });
    expect(groupsSummary([...ROWS, removed, solo])).toEqual({
      groups: [{ planId: PLAN_T, label: "Tunde's group", count: 3 }],
      // Omar's Plan has one confirmed booking left, so he and Yusuf booked alone.
      alone: 2,
    });
  });

  it('finds a guest by name or by ref with or without the prefix', () => {
    const z = ROWS[1]!;
    expect(matchesGuest(z, 'zain')).toBe(true);
    expect(matchesGuest(z, 'VLO-48213')).toBe(true);
    expect(matchesGuest(z, 'vlo 482')).toBe(true);
    expect(matchesGuest(z, '48213')).toBe(true);
    expect(matchesGuest(z, 'kofi')).toBe(false);
    expect(matchesGuest(z, '  ')).toBe(true);
  });

  it('orders newest first before the start, booking order after, removed last', () => {
    const removed = attendee(4, { status: 'removed', bookedAt: '2026-12-09T08:00:00Z' });
    const ids = (xs: Attendee[]) => xs.map((a) => a.bookingId);
    expect(ids(orderAttendees([...ROWS, removed], false))).toEqual(
      ids([ROWS[3]!, ROWS[2]!, ROWS[1]!, ROWS[0]!, removed]),
    );
    expect(ids(orderAttendees([removed, ...ROWS], true))).toEqual(ids([...ROWS, removed]));
  });

  it('counts bookings, invites and marks over confirmed bookings only', () => {
    const rows = [
      { ...ROWS[0]!, mark: 'attended' as const },
      { ...ROWS[1]!, mark: 'no_show' as const },
      ROWS[2]!,
      { ...ROWS[3]!, status: 'removed' as const, mark: 'attended' as const },
    ];
    expect(attendanceStats(attendance({}, rows))).toEqual({
      booked: 3,
      capacity: 14,
      throughInvites: 2,
      marked: 2,
      attended: 1,
      noShows: 1,
    });
  });

  it('explains failed marks', () => {
    expect(markFailure(new ApiRequestError(409, 'booking_removed', 'x'), 'Zainab Okafor')).toBe(
      'Zainab was removed, so they can’t be marked.',
    );
    expect(markFailure(new ApiRequestError(409, 'activity_not_started', 'x'), 'Z')).toMatch(
      /once the activity starts/,
    );
    expect(markFailure(new ApiRequestError(0, 'network', 'x'), 'Z')).toMatch(/offline/);
    expect(markFailure(new Error('x'), 'Z')).toBe('We couldn’t save that mark. Try again.');
  });
});

describe('H1 attendance', () => {
  it('shows bookings with full names, refs and sources, never contacts, and subscribes to both topics', () => {
    const client = renderLive(attendance());
    const list = within(going());
    expect(list.getByText('Going')).toBeInTheDocument();
    expect(list.getByText('Newest first')).toBeInTheDocument();
    expect(list.getByText('Zainab Okafor')).toBeInTheDocument();
    expect(list.getByText('VLO-48213 · Booked Wed 2 Dec')).toBeInTheDocument();
    expect(list.getByText('Via Tunde')).toBeInTheDocument();
    expect(list.getByText('Public link')).toBeInTheDocument();
    expect(list.getAllByRole('button', { name: 'Remove' })).toHaveLength(4);
    expect(screen.getAllByText(/Phone numbers, emails and invite notes stay private/).length).toBeGreaterThan(
      0,
    );
    expect(document.body.textContent).not.toMatch(/@|\+254/);
    expect(client.seen[0]!.topics).toEqual([`activity:${ID}`, `host:${ID}`]);
    // Groups summary (UX-3) and the desktop stats.
    expect(screen.getByText("Tunde's group")).toBeInTheDocument();
    expect(screen.getByText('Booked alone')).toBeInTheDocument();
    expect(screen.getByText('Through invites')).toBeInTheDocument();
    expect(screen.getAllByText('4 of 14').length).toBeGreaterThan(0);
    expect(screen.getByRole('link', { name: 'Edit activity' })).toHaveAttribute(
      'href',
      `/host/activities/${ID}/edit`,
    );
  });

  it('adds a live arrival on an attendance event, marked new', async () => {
    const nia = attendee(9, {
      bookingId: uuid(299),
      person: person(9, 'Nia Wambui'),
      bookedAt: '2026-12-10T07:59:00Z',
      ref: 'VLO-K8R4T',
      source: 'vouch',
      invitedBy: KOFI,
    });
    const fetch = stubFetch(() => json(attendance({ spotsLeft: 9, version: 5 }, [...ROWS, nia])));
    const client = renderLive(attendance());
    await act(async () => client.seen[0]!.onAttendance!(ID));
    expect(fetch.mock.calls[0]![0]).toBe(`/api/host/activities/${ID}/attendance`);
    const rows = within(going()).getAllByText(/^VLO-/);
    expect(rows[0]).toHaveTextContent('VLO-K8R4T · Booked just now');
    expect(within(going()).getByText('Via Kofi')).toBeInTheDocument();
    expect(within(going()).getByText('Nia Wambui').closest('.vl-listrow')).toHaveClass('is-new');
    expect(within(going()).getByText('Zainab Okafor').closest('.vl-listrow')).not.toHaveClass('is-new');
  });

  it('removes only after confirmation, then refetches', async () => {
    const after = ROWS.map((a, i) => (i === 1 ? { ...a, status: 'removed' as const } : a));
    const fetch = stubFetch((url) =>
      url.endsWith('/removal')
        ? json({ booking: {}, activity: {} })
        : json(attendance({ spotsLeft: 11, version: 5 }, after)),
    );
    renderLive(attendance());
    const zainab = within(going()).getByText('Zainab Okafor').closest('.vl-listrow') as HTMLElement;
    fireEvent.click(within(zainab).getByRole('button', { name: 'Remove' }));

    const dialog = screen.getAllByRole('dialog')[0]!;
    expect(within(dialog).getByText('Remove Zainab Okafor?')).toBeInTheDocument();
    expect(within(dialog).getByText(/opens to whoever books next/)).toBeInTheDocument();
    expect(fetch).not.toHaveBeenCalled();
    fireEvent.click(within(dialog).getByRole('button', { name: 'Keep' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();

    fireEvent.click(within(zainab).getByRole('button', { name: 'Remove' }));
    fireEvent.click(within(screen.getAllByRole('dialog')[0]!).getByRole('button', { name: 'Remove Zainab' }));
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    expect(fetch.mock.calls[0]![0]).toBe(`/api/host/bookings/${ROWS[1]!.bookingId}/removal`);
    expect(fetch.mock.calls[0]![1]!.method).toBe('POST');
    expect(screen.getByText('Zainab removed. Their spot is open again.')).toBeInTheDocument();
    const row = within(going()).getByText('Zainab Okafor').closest('.vl-listrow') as HTMLElement;
    expect(row).toHaveClass('is-removed');
    expect(within(row).queryByRole('button')).not.toBeInTheDocument();
    expect(within(row).getByText('VLO-48213 · Removed')).toBeInTheDocument();
  });

  it('Escape closes the confirmation', () => {
    renderLive(attendance());
    fireEvent.click(within(going()).getAllByRole('button', { name: 'Remove' })[0]!);
    fireEvent.keyDown(screen.getAllByRole('dialog')[0]!, { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('after the start marks attended or no-show, the latest mark winning, and removed rows unmarkable', async () => {
    vi.setSystemTime(Date.parse('2026-12-14T15:00:00Z'));
    const rows = [...ROWS.slice(0, 3), { ...ROWS[3]!, status: 'removed' as const }];
    const fetch = stubFetch((_url, init) => {
      const { mark } = JSON.parse(String(init!.body)) as { mark: string };
      return json({ ...rows[1]!, mark, markedAt: '2026-12-14T15:00:00Z' });
    });
    renderLive(attendance({ started: true }, rows));
    expect(screen.getAllByText('The activity has started.').length).toBeGreaterThan(0);
    expect(screen.getByRole('heading', { name: 'Who came?' })).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Edit activity' })).not.toBeInTheDocument();
    expect(within(going()).queryByRole('button', { name: 'Remove' })).not.toBeInTheDocument();

    const group = screen.getByRole('group', { name: 'Attendance for Zainab Okafor' });
    fireEvent.click(within(group).getByRole('button', { name: 'Attended' }));
    expect(within(group).getByRole('button', { name: 'Attended' })).toHaveAttribute('aria-pressed', 'true');
    await waitFor(() => expect(fetch).toHaveBeenCalledTimes(1));
    expect(fetch.mock.calls[0]![0]).toBe(`/api/host/bookings/${rows[1]!.bookingId}/attendance`);

    fireEvent.click(within(group).getByRole('button', { name: 'No-show' }));
    await waitFor(() =>
      expect(within(group).getByRole('button', { name: 'No-show' })).toHaveAttribute('aria-pressed', 'true'),
    );
    expect(within(group).getByRole('button', { name: 'Attended' })).toHaveAttribute('aria-pressed', 'false');
    expect(screen.getByText('1 of 3 marked')).toBeInTheDocument();
    expect(screen.queryByRole('group', { name: 'Attendance for Omar Mahmoud' })).not.toBeInTheDocument();
  });

  it('reverts a failed mark and says why', async () => {
    vi.setSystemTime(Date.parse('2026-12-14T15:00:00Z'));
    stubFetch((url) =>
      url.endsWith('/attendance') && !url.includes('/host/activities/')
        ? envelope('booking_removed', 409)
        : json(attendance({ started: true })),
    );
    renderLive(attendance({ started: true }));
    const group = screen.getByRole('group', { name: 'Attendance for Zainab Okafor' });
    fireEvent.click(within(group).getByRole('button', { name: 'Attended' }));
    expect(await screen.findByText('Zainab was removed, so they can’t be marked.')).toBeInTheDocument();
    expect(within(group).getByRole('button', { name: 'Attended' })).toHaveAttribute('aria-pressed', 'false');
  });

  it('phone search filters by name or ref', () => {
    renderLive(attendance());
    const search = screen.getByLabelText('Find a guest');
    fireEvent.change(search, { target: { value: 'c4n8' } });
    expect(within(going()).getByText('Omar Mahmoud')).toBeInTheDocument();
    expect(within(going()).queryByText('Zainab Okafor')).not.toBeInTheDocument();
    fireEvent.change(search, { target: { value: 'nobody' } });
    expect(screen.getByText('No guest matches “nobody”.')).toBeInTheDocument();
  });

  it('shows the empty state with the closing time', () => {
    renderLive(attendance({}, []));
    expect(screen.getByText('No bookings yet')).toBeInTheDocument();
    expect(
      screen.getByText(
        'This page updates by itself the moment someone books. Bookings close at 17:30 Nairobi time on Mon 14 Dec.',
      ),
    ).toBeInTheDocument();
    expect(screen.queryByLabelText('Find a guest')).not.toBeInTheDocument();
    expect(screen.queryByText('Groups')).not.toBeInTheDocument();
  });
});
