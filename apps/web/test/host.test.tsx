import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import type { HostActivityItem, HostActivityList } from '@velio/contracts';
import { ApiRequestError } from '@/lib/api/client';
import {
  createBody,
  formFromActivity,
  isoToZoned,
  parsePrice,
  patchBody,
  shortName,
  spotsHelp,
  summaryTitle,
  validate,
  zonedToIso,
  type HostForm,
} from '@/lib/host-form';
import { ActivityForm, saveFailure } from '@/components/host/activity-form';
import { HostList, hostRow } from '@/components/host/host-list';
import { ID, inviteView } from './fixtures';

const router = { push: vi.fn(), replace: vi.fn(), refresh: vi.fn() };
vi.mock('next/navigation', () => ({ useRouter: () => router }));
vi.mock('@/lib/photo', () => ({
  PhotoError: class extends Error {},
  uploadPhoto: vi.fn(async () => ({ key: `${ID}/photo.webp`, previewUrl: 'blob:photo' })),
}));
// The real picker is covered in maps.test.tsx; here a button stands in for picking a place.
vi.mock('@/components/maps-live', () => ({
  LocationPickerLive: ({
    onChange,
    errors,
  }: {
    onChange: (v: unknown) => void;
    errors: { location?: string | null };
  }) => (
    <div>
      <button
        type="button"
        onClick={() =>
          onChange({
            placeId: 'p1',
            venueName: 'Boat Club',
            addressText: 'Moi South Lake Rd',
            lat: -0.7,
            lng: 36.4,
          })
        }
      >
        Pick Boat Club
      </button>
      {errors.location ? <span>{errors.location}</span> : null}
    </div>
  ),
}));

const NOW = Date.parse('2026-11-04T12:00:00Z');

const filled = (over: Partial<HostForm> = {}): HostForm => ({
  communitySlug: 'explore-kenya',
  title: 'Sunset Kayaking',
  description: 'Two hours on the lake.',
  date: '2026-12-14',
  time: '17:30',
  timezone: 'Africa/Nairobi',
  location: { placeId: 'p1', venueName: 'Boat Club', addressText: 'Moi South Lake Rd', lat: -0.7, lng: 36.4 },
  meetingPoint: '',
  price: '3,500',
  capacity: 14,
  photoKey: `${ID}/photo.webp`,
  ...over,
});
const opts = { editing: false, locked: false, booked: 0, currency: 'KES', now: NOW };

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
const envelope = (code: string, status: number) =>
  json({ error: { code, message: code, requestId: 'r1' } }, status);

function stubFetch(handler: (url: string, init?: RequestInit) => Response) {
  const fetch = vi.fn(async (url: string, init?: RequestInit) => handler(String(url), init));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

beforeEach(() => {
  router.replace.mockReset();
  router.refresh.mockReset();
});
afterEach(() => vi.unstubAllGlobals());

describe('host form rules (V-HOST-2)', () => {
  test('wall-clock time in the zone becomes ISO with that zone’s offset, DST included', () => {
    expect(zonedToIso('2026-12-14', '17:30', 'Africa/Nairobi')).toBe('2026-12-14T17:30:00+03:00');
    expect(zonedToIso('2026-07-01', '09:00', 'Europe/London')).toBe('2026-07-01T09:00:00+01:00');
    expect(zonedToIso('2026-12-01', '09:00', 'Europe/London')).toBe('2026-12-01T09:00:00+00:00');
    expect(zonedToIso('2026-12-01', '09:00', 'America/New_York')).toBe('2026-12-01T09:00:00-05:00');
    expect(zonedToIso('2026-12-01', '', 'Africa/Nairobi')).toBeNull();
    expect(zonedToIso('2026-12-01', '09:00', 'Mars/Olympus')).toBeNull();
    expect(isoToZoned('2026-12-14T14:30:00Z', 'Africa/Nairobi')).toEqual({
      date: '2026-12-14',
      time: '17:30',
    });
  });

  test('prices parse in the currency’s minor units and must be above zero', () => {
    expect(parsePrice('3,500', 'KES')).toBe(350000);
    expect(parsePrice('12.5', 'KES')).toBe(1250);
    expect(parsePrice('12.345', 'KES')).toBeNull();
    expect(parsePrice('0', 'KES')).toBeNull();
    expect(parsePrice('free', 'KES')).toBeNull();
  });

  test('every copy-deck error, and none for a complete form', () => {
    expect(validate(filled(), opts)).toEqual({});
    const empty = filled({
      photoKey: null,
      title: ' ',
      date: '',
      time: '',
      timezone: 'Nowhere/Here',
      location: null,
      price: '',
      capacity: 0,
    });
    expect(validate(empty, opts)).toEqual({
      photo: 'Add a photo. It shows on the activity page and every invite.',
      title: 'Add a title.',
      date: 'Pick a date in the future.',
      time: 'Pick a start time.',
      timezone: 'Pick a time zone from the list.',
      location: 'Search for a place, or drop a pin on the map.',
      price: 'Enter the price per person.',
      capacity: 'At least 1 spot.',
    });
    expect(validate(filled({ date: '2026-11-01' }), opts).date).toBe('Pick a date in the future.');
    const typed = filled({ location: { placeId: null, venueName: '', addressText: '', lat: 1, lng: 2 } });
    expect(validate(typed, opts)).toEqual({
      venueName: 'Add the venue name.',
      addressText: 'Add the address.',
    });
  });

  test('after bookings: capacity floor, locked fields and price unchecked', () => {
    const locked = { ...opts, editing: true, locked: true, booked: 9 };
    const past = filled({ date: '2020-01-01', location: null, price: '' });
    expect(validate(past, locked)).toEqual({});
    expect(validate(filled({ capacity: 8 }), locked).capacity).toBe('9 booked, so at least 9.');
    expect(spotsHelp(9)).toBe('9 booked, so at least 9. You can always add more.');
    expect(spotsHelp(0)).toBe('You can add spots later, never fewer than people booked.');
    expect(summaryTitle(3, false)).toBe('3 things need fixing before you can publish.');
    expect(summaryTitle(1, true)).toBe('1 thing needs fixing before you can save.');
  });

  test('create body; patch has only changed fields and never locked ones', () => {
    expect(createBody(filled({ meetingPoint: ' Blue gate ' }))).toEqual({
      communitySlug: 'explore-kenya',
      title: 'Sunset Kayaking',
      description: 'Two hours on the lake.',
      startsAt: '2026-12-14T17:30:00+03:00',
      timezone: 'Africa/Nairobi',
      location: {
        placeId: 'p1',
        venueName: 'Boat Club',
        addressText: 'Moi South Lake Rd',
        lat: -0.7,
        lng: 36.4,
        meetingPoint: 'Blue gate',
      },
      priceMinor: 350000,
      currency: 'KES',
      capacity: 14,
      photoKey: `${ID}/photo.webp`,
    });
    const before = filled();
    const after = filled({ title: 'Night Kayaking', capacity: 20, date: '2026-12-15' });
    expect(patchBody(after, before, true)).toEqual({ title: 'Night Kayaking', capacity: 20 });
    expect(patchBody(after, before, false)).toEqual({
      title: 'Night Kayaking',
      capacity: 20,
      startsAt: '2026-12-15T17:30:00+03:00',
    });
    expect(patchBody(before, before, false)).toEqual({});
  });

  test('the edit form starts from the snapshot', () => {
    const a = inviteView({}, { photoUrl: `/photos/${ID}/p.webp` }).activity;
    expect(formFromActivity(a)).toMatchObject({
      date: '2026-12-14',
      time: '17:30',
      price: '3,500',
      capacity: 14,
      photoKey: `${ID}/p.webp`,
    });
    expect(shortName('Amara Otieno')).toBe('Amara O.');
  });

  test('API rejections land on their fields', () => {
    expect(saveFailure(new ApiRequestError(409, 'location_locked', 'x'))).toMatchObject({
      fields: { location: 'Date, time and place are locked now that people have booked.' },
      refresh: true,
    });
    expect(saveFailure(new ApiRequestError(409, 'capacity_below_bookings', 'x'))).toMatchObject({
      fields: { capacity: 'That’s fewer spots than people have booked.' },
    });
    expect(saveFailure(new ApiRequestError(0, 'network', 'x'))).toEqual({
      banner: 'Check your connection and try again.',
    });
  });
});

const COMMUNITIES = [
  { slug: 'explore-kenya', name: 'Explore Kenya' },
  { slug: 'the-medina-collective', name: 'The Medina Collective' },
];
const blank = (): HostForm => ({
  ...filled(),
  title: '',
  description: '',
  date: '',
  time: '',
  timezone: '',
  location: null,
  price: '',
  capacity: 10,
  photoKey: null,
});

describe('H2 create (V-HOST-2, FR-033)', () => {
  test('publishing an empty form shows the summary and each field’s error', () => {
    render(<ActivityForm communities={COMMUNITIES} host="Amara O." initial={blank()} />);
    fireEvent.click(screen.getByRole('button', { name: 'Publish' }));
    // Photo, title, date, start time, location, price; the zone defaults to the browser's.
    expect(screen.getByText('6 things need fixing before you can publish.')).toBeInTheDocument();
    expect(screen.getByText('Add a title.')).toBeInTheDocument();
    expect(
      screen.getByText('Add a photo. It shows on the activity page and every invite.'),
    ).toBeInTheDocument();
    expect(screen.getByText('Search for a place, or drop a pin on the map.')).toBeInTheDocument();
    expect((screen.getByLabelText('Time zone') as HTMLInputElement).value).not.toBe('');
    expect(screen.getByLabelText('Meeting point (optional)')).toHaveAttribute('maxlength', '140');
  });

  test('a complete form publishes and opens the published state; the preview follows the form', async () => {
    const fetch = stubFetch(() => json({ id: ID }, 201));
    render(<ActivityForm communities={COMMUNITIES} host="Amara O." initial={blank()} />);
    fireEvent.click(screen.getByRole('button', { name: 'Choose a photo' }));
    const file = document.querySelector<HTMLInputElement>('input[type=file]')!;
    fireEvent.change(file, { target: { files: [new File(['x'], 'p.jpg', { type: 'image/jpeg' })] } });
    await screen.findByRole('button', { name: 'Change photo' });
    fireEvent.change(screen.getByLabelText('Title'), { target: { value: 'Sunset Kayaking' } });
    fireEvent.change(screen.getByLabelText('Date'), { target: { value: '2030-12-14' } });
    fireEvent.change(screen.getByLabelText('Start time'), { target: { value: '17:30' } });
    fireEvent.change(screen.getByLabelText('Time zone'), { target: { value: 'Africa/Nairobi' } });
    fireEvent.click(screen.getByRole('button', { name: 'Pick Boat Club' }));
    fireEvent.change(screen.getByLabelText('Price per person (KES)'), { target: { value: '3,500' } });
    fireEvent.click(screen.getByRole('button', { name: 'One more spot' }));

    const preview = screen.getByRole('complementary', { name: 'Preview' });
    expect(within(preview).getByText('Sunset Kayaking')).toBeInTheDocument();
    expect(within(preview).getByText(/KES 3,500/)).toBeInTheDocument();
    expect(within(preview).getByText('Hosted by Amara O.')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'Publish' }));
    await waitFor(() =>
      expect(router.replace).toHaveBeenCalledWith(`/host/activities/${ID}/edit?published=1`),
    );
    const [url, init] = fetch.mock.calls[0]!;
    expect(url).toBe('/api/activities');
    expect(JSON.parse(String(init!.body))).toMatchObject({
      startsAt: '2030-12-14T17:30:00+03:00',
      priceMinor: 350000,
      currency: 'KES',
      capacity: 11,
      photoKey: `${ID}/photo.webp`,
    });
  });

  test('the price label and currency follow the community', () => {
    render(<ActivityForm communities={COMMUNITIES} host="Amara O." initial={blank()} />);
    fireEvent.change(screen.getByLabelText('Community'), { target: { value: 'the-medina-collective' } });
    expect(screen.getByLabelText('Price per person (MAD)')).toBeInTheDocument();
  });
});

describe('H2 edit (V-HOST-3, FR-034)', () => {
  const edit = (booked: number) => ({
    id: ID,
    booked,
    photoUrl: '/photos/p.webp',
    directionsUrl: 'https://www.google.com/maps/dir/?api=1&destination=-0.7,36.4',
    staticMapUrl: null,
    communityName: 'Explore Kenya',
    currency: 'KES',
  });

  test('after a booking: lock banner, read-only date, time and zone, location shown, capacity floor', async () => {
    const fetch = stubFetch(() => json({ id: ID }));
    render(
      <ActivityForm
        communities={COMMUNITIES}
        host="Amara O."
        initial={filled({ capacity: 9 })}
        edit={edit(9)}
      />,
    );
    expect(
      screen.getByText('Date, time and place are locked now that people have booked.'),
    ).toBeInTheDocument();
    for (const label of ['Date', 'Start time', 'Time zone', 'Price per person (KES)']) {
      expect(screen.getByLabelText(label)).toHaveAttribute('readonly');
    }
    expect(screen.getByText('Location is locked because people have booked.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Pick Boat Club' })).toBeNull();
    expect(screen.getByRole('button', { name: 'One fewer spot' })).toBeDisabled();
    expect(screen.getByText('9 booked, so at least 9. You can always add more.')).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText('Title'), { target: { value: 'Night Kayaking' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save changes' }));
    await screen.findByText('Changes saved');
    const [url, init] = fetch.mock.calls[0]!;
    expect(url).toBe(`/api/activities/${ID}`);
    expect(init!.method).toBe('PATCH');
    expect(JSON.parse(String(init!.body))).toEqual({ title: 'Night Kayaking' });
  });

  test('API rejections show inline and refresh the booked count', async () => {
    stubFetch(() => envelope('location_locked', 409));
    render(<ActivityForm communities={COMMUNITIES} host="Amara O." initial={filled()} edit={edit(0)} />);
    fireEvent.change(screen.getByLabelText('Date'), { target: { value: '2030-12-20' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save changes' }));
    expect(
      await screen.findAllByText('Date, time and place are locked now that people have booked.'),
    ).not.toHaveLength(0);
    expect(router.refresh).toHaveBeenCalled();

    stubFetch(() => envelope('capacity_below_bookings', 409));
    fireEvent.click(screen.getByRole('button', { name: 'One fewer spot' }));
    fireEvent.click(screen.getByRole('button', { name: 'Save changes' }));
    expect(await screen.findByText('That’s fewer spots than people have booked.')).toBeInTheDocument();
  });

  test('published state links to live attendance and the page', () => {
    render(
      <ActivityForm communities={COMMUNITIES} host="Amara O." initial={filled()} edit={edit(0)} published />,
    );
    expect(screen.getByText('Published. Sunset Kayaking is live in Explore Kenya.')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Open live attendance' })).toHaveAttribute(
      'href',
      `/host/activities/${ID}/attendance`,
    );
    expect(screen.getByRole('link', { name: 'View the page' })).toHaveAttribute('href', `/activities/${ID}`);
  });
});

const item = (over: Partial<HostActivityItem> = {}): HostActivityItem => {
  const a = inviteView().activity;
  return {
    id: ID,
    title: a.title,
    summary: '',
    startsAt: a.startsAt,
    timezone: a.timezone,
    priceMinor: a.priceMinor,
    currency: a.currency,
    photoUrl: null,
    capacity: 14,
    spotsLeft: 5,
    version: 1,
    status: 'open',
    community: a.community,
    location: { venueName: 'Boat Club', lat: -0.7, lng: 36.4 },
    members: { count: 9, preview: [] },
    bookedCount: 9,
    markedCount: 0,
    attendedCount: 0,
    ...over,
  };
};

describe('H3 (V-HOST-1, FR-032)', () => {
  test('status chips and actions follow the canvas', () => {
    expect(hostRow(item(), 'upcoming')).toMatchObject({
      status: '5 spots left',
      tone: 'lime',
      primary: { label: 'Attendance' },
      secondary: { label: 'Edit', href: `/host/activities/${ID}/edit` },
    });
    expect(hostRow(item({ spotsLeft: 0, bookedCount: 14 }), 'upcoming')).toMatchObject({
      status: 'Sold out',
      tone: 'forest',
    });
    expect(hostRow(item({ spotsLeft: 14, bookedCount: 0 }), 'upcoming')).toMatchObject({
      status: 'No bookings yet',
      primary: { label: 'View page', href: `/activities/${ID}` },
    });
    expect(hostRow(item({ status: 'started' }), 'past')).toMatchObject({
      status: 'Mark attendance',
      tone: 'danger',
      primary: { label: 'Mark now' },
      secondary: { label: 'View' },
    });
    expect(hostRow(item({ markedCount: 12, attendedCount: 11 }), 'past')).toMatchObject({
      status: '11 attended',
      tone: 'neutral',
    });
  });

  test('upcoming and past tabs; the empty state invites a first activity', () => {
    const data: HostActivityList = {
      upcoming: [item()],
      past: [
        item({ id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e99', title: 'Hell’s Gate cycle', status: 'started' }),
      ],
    };
    render(<HostList data={data} />);
    expect(screen.getAllByText('Sunset Kayaking').length).toBeGreaterThan(0);
    expect(screen.queryByText('Hell’s Gate cycle')).toBeNull();
    fireEvent.click(screen.getAllByRole('button', { name: 'Past' })[0]!);
    expect(screen.getAllByText('Hell’s Gate cycle').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Mark attendance').length).toBeGreaterThan(0);

    render(<HostList data={{ upcoming: [], past: [] }} />);
    expect(screen.getByText('No activities yet')).toBeInTheDocument();
  });
});
