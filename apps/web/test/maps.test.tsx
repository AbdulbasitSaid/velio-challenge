import { act, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { clusterPoints, nudge } from '@/lib/maps/geo';
import * as loader from '@/lib/maps/loader';
import {
  CommunityMapLive,
  ExploreMap,
  isLocationComplete,
  LocationPickerLive,
  type PickedLocation,
} from '@/components/maps-live';

// The loader is the only door to Google: tests decide whether Maps is configured and what loads.
vi.mock('@/lib/maps/loader', () => ({
  mapsConfigured: vi.fn(() => true),
  loadMaps: vi.fn(),
  loadPlaces: vi.fn(),
  onMapsAuthFailure: vi.fn(() => () => {}),
}));
const mocked = vi.mocked(loader);

// --- A small stand-in for google.maps: enough for the map, the overlay and Places. ---

type Listener = () => void;

class FakeLatLng {
  constructor(
    private readonly la: number,
    private readonly ln: number,
  ) {}
  lat() {
    return this.la;
  }
  lng() {
    return this.ln;
  }
}

const maps: FakeMap[] = [];

class FakeMap {
  center: { lat: number; lng: number };
  zoom: number;
  listeners = new Map<string, Set<Listener>>();
  // Like Google's, the pan animates: `idle` comes later (tests fire it).
  panTo = vi.fn((c: { lat: number; lng: number }) => {
    this.center = c;
  });
  fitBounds = vi.fn();
  constructor(
    readonly el: HTMLElement,
    readonly options: google.maps.MapOptions,
  ) {
    this.center = options.center as { lat: number; lng: number };
    this.zoom = options.zoom ?? 0;
    maps.push(this);
  }
  getCenter() {
    return new FakeLatLng(this.center.lat, this.center.lng);
  }
  getZoom() {
    return this.zoom;
  }
  setZoom(z: number) {
    this.zoom = z;
  }
  addListener(name: string, fn: Listener) {
    const set = this.listeners.get(name) ?? new Set();
    set.add(fn);
    this.listeners.set(name, set);
    return { remove: () => set.delete(fn) };
  }
  fire(name: string) {
    for (const fn of this.listeners.get(name) ?? []) fn();
  }
}

class FakeOverlayView {
  static preventMapHitsAndGesturesFrom() {}
  private pane = document.createElement('div');
  setMap(map: FakeMap | null) {
    if (map) {
      map.el.appendChild(this.pane);
      (this as unknown as { onAdd(): void }).onAdd();
      (this as unknown as { draw(): void }).draw();
    } else {
      (this as unknown as { onRemove(): void }).onRemove();
    }
  }
  getPanes() {
    return { overlayMouseTarget: this.pane };
  }
  // 1° = 1000 px, so two points 0.01° apart are 10 px apart and cluster.
  getProjection() {
    return {
      fromLatLngToDivPixel: (ll: FakeLatLng) => ({ x: ll.lng() * 1000, y: -ll.lat() * 1000 }),
    };
  }
}

class FakeBounds {
  points: { lat: number; lng: number }[] = [];
  extend(p: { lat: number; lng: number }) {
    this.points.push({ lat: p.lat, lng: p.lng });
  }
  toSpan() {
    const span = (k: 'lat' | 'lng') =>
      Math.max(...this.points.map((p) => p[k])) - Math.min(...this.points.map((p) => p[k]));
    return new FakeLatLng(span('lat'), span('lng'));
  }
}

const fetchAutocompleteSuggestions = vi.fn();

function prediction(placeId: string, main: string, sub: string, place: Record<string, unknown>) {
  return {
    placePrediction: {
      placeId,
      text: { text: `${main}, ${sub}` },
      mainText: { text: main },
      secondaryText: { text: sub },
      toPlace: () => ({ ...place, fetchFields: vi.fn(async () => ({})) }),
    },
  };
}

beforeEach(() => {
  maps.length = 0;
  vi.stubGlobal('google', {
    maps: { LatLng: FakeLatLng, OverlayView: FakeOverlayView, LatLngBounds: FakeBounds },
  });
  mocked.mapsConfigured.mockReturnValue(true);
  mocked.loadMaps.mockResolvedValue({
    maps: { Map: FakeMap } as unknown as google.maps.MapsLibrary,
    core: {} as google.maps.CoreLibrary,
  });
  mocked.loadPlaces.mockResolvedValue({
    AutocompleteSessionToken: class {},
    AutocompleteSuggestion: { fetchAutocompleteSuggestions },
  } as unknown as google.maps.PlacesLibrary);
  fetchAutocompleteSuggestions.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.clearAllMocks();
});

describe('geo helpers', () => {
  // V-MAP-2 (Maps NFR-004)
  test('arrow keys nudge about 10 m; other keys do nothing', () => {
    const start = { lat: -1.2921, lng: 36.8219 };
    const up = nudge(start, 'ArrowUp')!;
    expect((up.lat - start.lat) * 111_320).toBeCloseTo(10, 5);
    const right = nudge(start, 'ArrowRight')!;
    const metres = (right.lng - start.lng) * 111_320 * Math.cos((start.lat * Math.PI) / 180);
    expect(metres).toBeCloseTo(10, 5);
    expect(nudge(start, 'Enter')).toBeNull();
    expect(nudge({ lat: 0, lng: 179.99995 }, 'ArrowRight')!.lng).toBeLessThan(-179);
  });

  // V-MAP-4 (FR-020)
  test('points within the radius cluster; far ones stay apart', () => {
    const clusters = clusterPoints([
      { x: 0, y: 0 },
      { x: 20, y: 0 },
      { x: 300, y: 300 },
    ]);
    expect(clusters).toEqual([
      { members: [0, 1], x: 10, y: 0 },
      { members: [2], x: 300, y: 300 },
    ]);
  });

  test('a location is complete with a pin, venue and address', () => {
    const loc = { placeId: null, venueName: 'Jetty', addressText: 'Naivasha', lat: -0.7, lng: 36.4 };
    expect(isLocationComplete(loc)).toBe(true);
    expect(isLocationComplete({ ...loc, lat: NaN })).toBe(false);
    expect(isLocationComplete({ ...loc, venueName: ' ' })).toBe(false);
    expect(isLocationComplete(null)).toBe(false);
  });
});

function Picker({ initial = null }: { initial?: PickedLocation | null }) {
  const [value, setValue] = useState<PickedLocation | null>(initial);
  return (
    <>
      <LocationPickerLive value={value} onChange={setValue} />
      <output data-testid="value">{JSON.stringify(value)}</output>
    </>
  );
}
const current = () => JSON.parse(screen.getByTestId('value').textContent!) as PickedLocation | null;

describe('LocationPickerLive (H2, FR-017)', () => {
  // V-MAP-2
  test('search, pick a place: venue, address and pin prefill; the pin-is-public note shows', async () => {
    const user = userEvent.setup();
    fetchAutocompleteSuggestions.mockResolvedValue({
      suggestions: [
        prediction('place-1', 'Lake Naivasha Boat Club', 'Moi South Lake Rd, Naivasha', {
          id: 'place-1',
          displayName: 'Lake Naivasha Boat Club',
          formattedAddress: 'Moi South Lake Rd, Naivasha, Kenya',
          location: new FakeLatLng(-0.7667, 36.4333),
        }),
        prediction('place-2', 'Naivasha Town', 'Kenya', {}),
      ],
    });
    render(<Picker />);
    expect(screen.getByText(/The pin, address and meeting point are public/)).toBeInTheDocument();
    expect(mocked.loadMaps).not.toHaveBeenCalled();

    const search = screen.getByRole('combobox', { name: 'Location' });
    await user.type(search, 'naivasha');
    const option = await screen.findByRole('option', { name: /Lake Naivasha Boat Club/ });
    expect(search).toHaveAttribute('aria-expanded', 'true');
    expect(option).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByText('Search by Google')).toBeInTheDocument();
    // Biased towards the default centre, one session token for the typing.
    expect(fetchAutocompleteSuggestions).toHaveBeenLastCalledWith(
      expect.objectContaining({ input: 'naivasha', locationBias: { lat: -1.2921, lng: 36.8219 } }),
    );

    await user.keyboard('{Enter}');
    await waitFor(() =>
      expect(current()).toEqual({
        placeId: 'place-1',
        venueName: 'Lake Naivasha Boat Club',
        addressText: 'Moi South Lake Rd, Naivasha, Kenya',
        lat: -0.7667,
        lng: 36.4333,
      }),
    );
    // The picked name fills the field without starting another search (found in Chrome).
    const calls = fetchAutocompleteSuggestions.mock.calls.length;
    await new Promise((r) => setTimeout(r, 400));
    expect(fetchAutocompleteSuggestions).toHaveBeenCalledTimes(calls);
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
    expect(search).toHaveValue('Lake Naivasha Boat Club');
    expect(screen.getByLabelText('Venue name')).toHaveValue('Lake Naivasha Boat Club');
    expect(screen.getByLabelText('Address')).toHaveValue('Moi South Lake Rd, Naivasha, Kenya');
    await waitFor(() => expect(maps).toHaveLength(1));
    expect(maps[0]!.options).toMatchObject({ keyboardShortcuts: false, gestureHandling: 'greedy' });
  });

  test('no results and a search failure each say to drop a pin', async () => {
    const user = userEvent.setup();
    fetchAutocompleteSuggestions.mockResolvedValueOnce({ suggestions: [] });
    render(<Picker />);
    await user.type(screen.getByRole('combobox'), 'zzqx');
    expect(await screen.findByText(/No places match “zzqx”/)).toBeInTheDocument();

    fetchAutocompleteSuggestions.mockRejectedValueOnce(new Error('network'));
    await user.type(screen.getByRole('combobox'), 'y');
    expect(await screen.findByText(/Place search isn’t available right now/)).toBeInTheDocument();
  });

  test('drop a pin without a place, drag the map, nudge with arrow keys', async () => {
    const user = userEvent.setup();
    render(<Picker />);
    await user.click(screen.getByRole('button', { name: 'Drop a pin without a place' }));
    expect(current()).toMatchObject({ placeId: null, venueName: '', lat: -1.2921, lng: 36.8219 });
    await waitFor(() => expect(maps).toHaveLength(1));

    // Dragging ends with the map idle at a new centre: that is the pin.
    act(() => {
      maps[0]!.center = { lat: -1.3, lng: 36.8 };
      maps[0]!.fire('idle');
    });
    expect(current()).toMatchObject({ lat: -1.3, lng: 36.8 });

    // Three presses during one pan add up (found in Chrome: they used to land on the same spot).
    const map = screen.getByRole('application');
    map.focus();
    await user.keyboard('{ArrowUp}{ArrowUp}{ArrowUp}');
    act(() => maps[0]!.fire('idle'));
    expect(current()!.lat).toBeCloseTo(-1.3 + 30 / 111_320, 9);

    await user.type(screen.getByLabelText('Venue name'), 'Karura gate');
    expect(current()).toMatchObject({ venueName: 'Karura gate' });
  });

  // V-MAP-5 (FR-021)
  test('without Maps: venue, address and coordinates fields, validated', async () => {
    mocked.mapsConfigured.mockReturnValue(false);
    const user = userEvent.setup();
    render(<Picker />);
    expect(screen.queryByRole('combobox')).not.toBeInTheDocument();
    expect(screen.getByText(/The map didn’t load/)).toBeInTheDocument();
    await user.type(screen.getByLabelText('Venue name'), 'Boat Club');
    await user.type(screen.getByLabelText('Address'), 'Naivasha');
    await user.type(screen.getByLabelText('Latitude'), '-0.7667');
    await user.type(screen.getByLabelText('Longitude'), '200');
    expect(screen.getByText('Between -180 and 180')).toBeInTheDocument();
    expect(isLocationComplete(current())).toBe(false);
    await user.clear(screen.getByLabelText('Longitude'));
    await user.type(screen.getByLabelText('Longitude'), '36.4333');
    expect(current()).toEqual({
      placeId: null,
      venueName: 'Boat Club',
      addressText: 'Naivasha',
      lat: -0.7667,
      lng: 36.4333,
    });
    expect(mocked.loadMaps).not.toHaveBeenCalled();
  });

  test('a map that fails to load falls back to the manual fields', async () => {
    mocked.loadMaps.mockRejectedValue(new Error('blocked'));
    render(
      <Picker
        initial={{ placeId: 'p', venueName: 'Jetty', addressText: 'Naivasha', lat: -0.7, lng: 36.4 }}
      />,
    );
    expect(await screen.findByLabelText('Latitude')).toHaveValue('-0.7');
    expect(screen.getByLabelText('Venue name')).toHaveValue('Jetty');
  });

  test('locked after a booking: no search, fields read-only', async () => {
    render(
      <LocationPickerLive
        locked
        value={{ placeId: 'p', venueName: 'Jetty', addressText: 'Naivasha', lat: -0.7, lng: 36.4 }}
        onChange={() => {}}
      />,
    );
    expect(screen.queryByRole('combobox')).not.toBeInTheDocument();
    expect(screen.getByLabelText('Venue name')).toHaveAttribute('readonly');
    await waitFor(() => expect(maps[0]?.options.gestureHandling).toBe('none'));
  });
});

describe('ExploreMap (B1, FR-018)', () => {
  // V-MAP-6 (NFR-004)
  test('the static image costs no script; a tap loads the interactive map with the pin', async () => {
    const user = userEvent.setup();
    render(
      <ExploreMap lat={-0.7667} lng={36.4333} venue="Boat Club" staticMapUrl="https://maps.example/s.png" />,
    );
    expect(mocked.loadMaps).not.toHaveBeenCalled();
    await user.click(screen.getByRole('button', { name: 'Explore the map of Boat Club' }));
    await waitFor(() => expect(maps).toHaveLength(1));
    expect(maps[0]!.options).toMatchObject({ center: { lat: -0.7667, lng: 36.4333 }, zoom: 15 });
    expect(
      screen.getByRole('region', { name: 'Map of Boat Club' }).querySelector('.vl-map-pin'),
    ).toBeTruthy();
    await user.click(screen.getByRole('button', { name: 'Zoom in' }));
    expect(maps[0]!.zoom).toBe(16);
  });

  // V-MAP-3, V-MAP-5 (A7)
  test('no static image: a button when Maps is configured, nothing otherwise', () => {
    const { rerender } = render(<ExploreMap lat={0} lng={0} venue="V" staticMapUrl={null} />);
    expect(screen.getByRole('button', { name: 'Show the map' })).toBeInTheDocument();
    mocked.mapsConfigured.mockReturnValue(false);
    rerender(<ExploreMap lat={0} lng={0} venue="W" staticMapUrl={null} />);
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});

describe('CommunityMapLive (C1, FR-020)', () => {
  const points = [
    { id: 'a', lat: -1.3, lng: 36.8, label: '3 left', title: 'Karura walk' },
    { id: 'b', lat: -1.305, lng: 36.805, label: 'Last spot', title: 'Ngong hike' },
    { id: 'c', lat: -0.7, lng: 36.4, label: '6 left', title: 'Sunset kayaking' },
  ];

  // V-MAP-4
  test('clusters nearby markers; a marker opens its card; a cluster zooms in', async () => {
    const user = userEvent.setup();
    render(<CommunityMapLive points={points} renderCard={(id) => <p>Card {id}</p>} onShowList={() => {}} />);
    const cluster = await screen.findByRole('button', { name: '2 activities here. Zoom in' });
    expect(maps[0]!.fitBounds).toHaveBeenCalledTimes(1);

    await user.click(screen.getByRole('button', { name: 'Sunset kayaking, 6 left' }));
    expect(screen.getByText('Card c')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Sunset kayaking, 6 left' })).toHaveAttribute(
      'aria-pressed',
      'true',
    );

    await user.click(cluster);
    expect(maps[0]!.fitBounds).toHaveBeenCalledTimes(2);

    act(() => maps[0]!.fire('click'));
    expect(screen.queryByText('Card c')).not.toBeInTheDocument();
  });

  // V-MAP-5 (FR-021)
  test('when Maps is unavailable it offers the list', async () => {
    mocked.loadMaps.mockRejectedValue(new Error('blocked'));
    const onShowList = vi.fn();
    const user = userEvent.setup();
    render(<CommunityMapLive points={points} renderCard={() => null} onShowList={onShowList} />);
    await user.click(await screen.findByRole('button', { name: 'Show the list instead' }));
    expect(onShowList).toHaveBeenCalled();
  });
});
