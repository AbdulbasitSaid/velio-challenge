'use client';
// Live Google Maps surfaces (S5 T10, §4.10): the interactive map behind B1's static image, the H2
// location picker and the C1 community map. Each loads the Maps script only when it mounts (NFR-004)
// and falls back to the address or the list when Maps is unavailable (FR-021). Markers and the pin are
// the design system's own HTML, drawn in an overlay, so no Map ID or marker library is needed.
import { useEffect, useId, useRef, useState, type KeyboardEvent, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { clusterPoints, nudge, type Cluster, type LatLng, type PixelPoint } from '@/lib/maps/geo';
import { loadMaps, loadPlaces, mapsConfigured, onMapsAuthFailure, type MapsStatus } from '@/lib/maps/loader';
import { MapView, PIN_PUBLIC_NOTE } from './maps';
import { Button, Chip, cx, Icon, TextField } from './primitives';

const BASE_OPTIONS: google.maps.MapOptions = {
  disableDefaultUI: true,
  clickableIcons: false,
  // Pages scroll on phones; one finger scrolls the page, two move the map.
  gestureHandling: 'cooperative',
};

/** Mounts a Google map in `ref` once the script loads. `options` is read once. */
function useGoogleMap(options: google.maps.MapOptions) {
  const ref = useRef<HTMLDivElement>(null);
  const [initial] = useState(options);
  const [state, setState] = useState<{ status: MapsStatus; map: google.maps.Map | null }>(() => ({
    status: mapsConfigured() ? 'loading' : 'unavailable',
    map: null,
  }));
  useEffect(() => {
    if (!mapsConfigured()) return;
    let cancelled = false;
    const off = onMapsAuthFailure(() => setState({ status: 'unavailable', map: null }));
    loadMaps().then(
      ({ maps }) => {
        if (cancelled || !ref.current) return;
        setState({ status: 'ready', map: new maps.Map(ref.current, { ...BASE_OPTIONS, ...initial }) });
      },
      () => {
        if (!cancelled) setState({ status: 'unavailable', map: null });
      },
    );
    return () => {
      cancelled = true;
      off();
    };
  }, [initial]);
  return { ref, ...state };
}

/**
 * An overlay pane on `map` and the pixel position of each point in it. Positions update on zoom and
 * resize; panning moves the pane as a whole, so they stay right without a redraw.
 */
function useOverlay(map: google.maps.Map | null, points: LatLng[]) {
  const [layer, setLayer] = useState<{ pane: HTMLElement; pixels: PixelPoint[] } | null>(null);
  const key = JSON.stringify(points);
  useEffect(() => {
    if (!map) return;
    const latLngs = (JSON.parse(key) as LatLng[]).map((p) => new google.maps.LatLng(p.lat, p.lng));
    const pane = document.createElement('div');
    pane.style.position = 'absolute';
    google.maps.OverlayView.preventMapHitsAndGesturesFrom(pane);
    class Layer extends google.maps.OverlayView {
      override onAdd() {
        this.getPanes()?.overlayMouseTarget.appendChild(pane);
      }
      override draw() {
        const projection = this.getProjection();
        if (!projection) return;
        const pixels = latLngs.map((ll) => {
          const p = projection.fromLatLngToDivPixel(ll);
          return { x: p?.x ?? 0, y: p?.y ?? 0 };
        });
        setLayer({ pane, pixels });
      }
      override onRemove() {
        pane.remove();
      }
    }
    const overlay = new Layer();
    overlay.setMap(map);
    return () => {
      overlay.setMap(null);
      setLayer(null);
    };
  }, [map, key]);
  return layer;
}

function Pin({ x, y }: { x?: number; y?: number }) {
  const at = x == null || y == null ? { left: '50%', top: '50%' } : { left: x, top: y };
  return (
    <svg className="vl-map-pin" viewBox="0 0 36 46" aria-hidden style={{ ...at, pointerEvents: 'none' }}>
      <path d="M18 45s15-14.5 15-27A15 15 0 0 0 3 18c0 12.5 15 27 15 27z" style={{ fill: 'var(--forest)' }} />
      <circle cx={18} cy={18} r={6.5} style={{ fill: 'var(--lime)' }} />
    </svg>
  );
}

function ZoomButtons({ map }: { map: google.maps.Map }) {
  const zoom = (by: number) => map.setZoom((map.getZoom() ?? 14) + by);
  return (
    <div className="vl-map-controls">
      <button className="vl-iconbtn" type="button" aria-label="Zoom in" onClick={() => zoom(1)}>
        <Icon name="plus" />
      </button>
      <button className="vl-iconbtn" type="button" aria-label="Zoom out" onClick={() => zoom(-1)}>
        <Icon name="minus" />
      </button>
    </div>
  );
}

/** The interactive map with the activity's pin (B1 after a tap, Maps FR-006). */
export function LiveMap({
  lat,
  lng,
  venue,
  ratio,
  zoom = 15,
}: {
  lat: number;
  lng: number;
  venue: string;
  ratio?: string;
  zoom?: number;
}) {
  const { ref, status, map } = useGoogleMap({ center: { lat, lng }, zoom });
  const layer = useOverlay(map, [{ lat, lng }]);
  if (status === 'unavailable') return <MapView state="failed" venue={venue} ratio={ratio} />;
  return (
    <div
      className="vl-map"
      role="region"
      aria-label={`Map of ${venue}`}
      style={ratio ? { aspectRatio: ratio } : undefined}
    >
      <div ref={ref} style={{ position: 'absolute', inset: 0 }} />
      {status === 'loading' ? (
        <div className="vl-skel" style={{ position: 'absolute', inset: 0, borderRadius: 0 }} />
      ) : null}
      {layer?.pixels[0]
        ? createPortal(<Pin x={layer.pixels[0].x} y={layer.pixels[0].y} />, layer.pane)
        : null}
      {map ? <ZoomButtons map={map} /> : null}
    </div>
  );
}

/**
 * B1's map (FR-018): the signed static image, which costs no script; a tap swaps in the interactive
 * map. Without a static image but with Maps configured, a button loads the map instead. With neither,
 * nothing shows and the address stands alone (A7).
 */
export function ExploreMap({
  lat,
  lng,
  venue,
  staticMapUrl,
  ratio = '2 / 1',
}: {
  lat: number;
  lng: number;
  venue: string;
  staticMapUrl: string | null;
  ratio?: string;
}) {
  const [live, setLive] = useState(false);
  if (live) return <LiveMap lat={lat} lng={lng} venue={venue} ratio={ratio} />;
  if (staticMapUrl) {
    return (
      <button
        type="button"
        className="vl-map-explore"
        onClick={() => setLive(true)}
        aria-label={`Explore the map of ${venue}`}
        style={{
          display: 'block',
          width: '100%',
          padding: 0,
          border: 0,
          background: 'none',
          cursor: 'pointer',
        }}
      >
        <MapView state="static" venue={venue} staticMapUrl={staticMapUrl} tapHint ratio={ratio} />
      </button>
    );
  }
  if (!mapsConfigured()) return null;
  return (
    <Button variant="secondary" small icon="map" onClick={() => setLive(true)}>
      Show the map
    </Button>
  );
}

/** The place as the host confirms it (Maps MAP-D4): the stored values are the host's, not Google's. */
export interface PickedLocation {
  placeId: string | null;
  venueName: string;
  addressText: string;
  lat: number;
  lng: number;
}

/** FR-017: publishing needs a pin, a venue name and an address. Manual coordinates may be half-typed. */
export function isLocationComplete(loc: PickedLocation | null): loc is PickedLocation {
  return (
    loc !== null &&
    Number.isFinite(loc.lat) &&
    Number.isFinite(loc.lng) &&
    loc.venueName.trim() !== '' &&
    loc.addressText.trim() !== ''
  );
}

interface Suggestion {
  id: string;
  name: string;
  sub: string;
  prediction: google.maps.places.PlacePrediction;
}

const SEARCH_DEBOUNCE_MS = 250;

/** Nairobi: Explore Kenya, the first community (PRD release plan). */
const DEFAULT_CENTER: LatLng = { lat: -1.2921, lng: 36.8219 };

/**
 * H2's location picker (FR-017): Places search prefills venue, address and the pin; the pin sits at
 * the map's centre and the map drags under it; arrow keys nudge it ~10 m; a pin can be dropped without
 * a place. Without Maps, venue, address and coordinates are typed in (FR-021).
 */
export function LocationPickerLive({
  value,
  onChange,
  defaultCenter = DEFAULT_CENTER,
  errors = {},
  locked = false,
}: {
  value: PickedLocation | null;
  onChange: (value: PickedLocation | null) => void;
  /** Where "Drop a pin" starts and what search prefers, e.g. the community's city. */
  defaultCenter?: LatLng;
  errors?: { location?: string | null; venueName?: string | null; addressText?: string | null };
  /** After the first booking (Maps FR-005): shown, not editable. */
  locked?: boolean;
}) {
  const [mapsOk] = useState(mapsConfigured);
  const [failed, setFailed] = useState(false);
  useEffect(() => onMapsAuthFailure(() => setFailed(true)), []);
  if (!mapsOk || failed) {
    return <ManualLocation value={value} onChange={onChange} errors={errors} locked={locked} />;
  }
  return (
    <div className="vl-picker">
      {locked ? null : (
        <PlaceSearch
          bias={value ?? defaultCenter}
          error={errors.location}
          onPick={onChange}
          onDropPin={() =>
            onChange(value ?? { placeId: null, venueName: '', addressText: '', ...defaultCenter })
          }
        />
      )}
      {value ? (
        <>
          <PinMap value={value} onChange={onChange} locked={locked} onUnavailable={() => setFailed(true)} />
          <LocationTextFields value={value} onChange={onChange} errors={errors} locked={locked} />
        </>
      ) : null}
      <p className="vl-public-note" style={{ margin: 0 }}>
        <Icon name="info" />
        {PIN_PUBLIC_NOTE}
      </p>
    </div>
  );
}

function PlaceSearch({
  bias,
  error,
  onPick,
  onDropPin,
}: {
  bias: LatLng;
  error?: string | null;
  onPick: (value: PickedLocation) => void;
  onDropPin: () => void;
}) {
  const id = useId();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Suggestion[] | null>(null);
  const [active, setActive] = useState(0);
  const [searchFailed, setSearchFailed] = useState(false);
  const token = useRef<google.maps.places.AutocompleteSessionToken | null>(null);
  const request = useRef(0);
  /** The name a pick put in the field: not a new search (nor is the bias moving to the new pin). */
  const filled = useRef<string | null>(null);
  const biasKey = `${bias.lat},${bias.lng}`;

  useEffect(() => {
    const input = query.trim();
    const n = ++request.current;
    if (input.length < 2 || input === filled.current) return;
    const timer = setTimeout(async () => {
      try {
        const places = await loadPlaces();
        token.current ??= new places.AutocompleteSessionToken();
        const [lat, lng] = biasKey.split(',').map(Number) as [number, number];
        const { suggestions } = await places.AutocompleteSuggestion.fetchAutocompleteSuggestions({
          input,
          sessionToken: token.current,
          locationBias: { lat, lng },
        });
        if (n !== request.current) return;
        setSearchFailed(false);
        setActive(0);
        setResults(
          suggestions.flatMap((s) =>
            s.placePrediction
              ? [
                  {
                    id: s.placePrediction.placeId,
                    name: s.placePrediction.mainText?.text ?? s.placePrediction.text.text,
                    sub: s.placePrediction.secondaryText?.text ?? '',
                    prediction: s.placePrediction,
                  },
                ]
              : [],
          ),
        );
      } catch {
        if (n === request.current) setSearchFailed(true);
      }
    }, SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [query, biasKey]);

  async function pick(s: Suggestion) {
    setResults(null);
    try {
      const place = s.prediction.toPlace();
      await place.fetchFields({ fields: ['id', 'displayName', 'formattedAddress', 'location'] });
      // The session ends with the details request (Places billing).
      token.current = null;
      if (!place.location) throw new Error('place without a location');
      filled.current = (place.displayName ?? s.name).trim();
      setQuery(place.displayName ?? s.name);
      onPick({
        placeId: place.id,
        venueName: place.displayName ?? s.name,
        addressText: place.formattedAddress ?? s.sub,
        lat: place.location.lat(),
        lng: place.location.lng(),
      });
    } catch {
      setSearchFailed(true);
    }
  }

  const open = results !== null && results.length > 0 && query.trim().length >= 2;
  const noResults = results !== null && results.length === 0 && query.trim().length >= 2;
  function onKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (!open) return;
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      const step = e.key === 'ArrowDown' ? 1 : -1;
      setActive((a) => (a + step + results.length) % results.length);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      void pick(results[active]!);
    } else if (e.key === 'Escape') {
      setResults(null);
    }
  }

  const message = searchFailed
    ? 'Place search isn’t available right now. Drop a pin on the map instead.'
    : noResults
      ? `No places match “${query.trim()}”. Check the spelling, or drop a pin on the map.`
      : (error ?? null);
  const inputId = `${id}-search`;
  const listId = `${id}-results`;
  return (
    <>
      <div className={cx('vl-field', 'vl-field-search', message && 'has-error')}>
        <label htmlFor={inputId}>Location</label>
        <div style={{ position: 'relative' }}>
          <Icon name="search" />
          <input
            id={inputId}
            type="text"
            role="combobox"
            aria-expanded={open}
            aria-controls={listId}
            aria-autocomplete="list"
            aria-activedescendant={open ? `${listId}-${active}` : undefined}
            aria-invalid={message ? true : undefined}
            aria-describedby={message ? `${inputId}-err` : undefined}
            autoComplete="off"
            placeholder="Search for a place or address"
            value={query}
            onChange={(e) => {
              filled.current = null;
              setQuery(e.currentTarget.value);
              if (e.currentTarget.value.trim().length < 2) setResults(null);
            }}
            onKeyDown={onKeyDown}
          />
        </div>
        {message ? (
          <span className="vl-field-error" id={`${inputId}-err`}>
            <Icon name="alert" />
            {message}
          </span>
        ) : null}
      </div>
      {open ? (
        <div className="vl-pickres" role="listbox" id={listId} aria-label="Places">
          {results.map((r, i) => (
            <button
              key={r.id}
              id={`${listId}-${i}`}
              type="button"
              role="option"
              aria-selected={i === active}
              tabIndex={-1}
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => void pick(r)}
            >
              <Icon name="pin" />
              <span>
                <strong>{r.name}</strong>
                <span className="vl-pickres-sub">{r.sub}</span>
              </span>
            </button>
          ))}
          <div className="vl-pickres-foot">Search by Google</div>
        </div>
      ) : null}
      <div>
        <Button variant="quiet" small icon="target" onClick={onDropPin}>
          Drop a pin without a place
        </Button>
      </div>
    </>
  );
}

const SAME = 1e-7;

function PinMap({
  value,
  onChange,
  locked,
  onUnavailable,
}: {
  value: PickedLocation;
  onChange: (value: PickedLocation) => void;
  locked: boolean;
  onUnavailable: () => void;
}) {
  const { ref, status, map } = useGoogleMap({
    center: { lat: value.lat, lng: value.lng },
    zoom: 16,
    // The pin is the map's centre: dragging the map moves it. Our own keys nudge it (Maps NFR-004).
    gestureHandling: locked ? 'none' : 'greedy',
    keyboardShortcuts: false,
  });
  const latest = useRef({ value, onChange });
  useEffect(() => {
    latest.current = { value, onChange };
  });
  /** Where the map is panning to: key presses during the animation build on it, not on the old pin. */
  const target = useRef<LatLng | null>(null);

  useEffect(() => {
    if (status === 'unavailable') onUnavailable();
  }, [status, onUnavailable]);

  // A new value from search or typing recentres the map.
  useEffect(() => {
    const c = map?.getCenter();
    if (map && c && (Math.abs(c.lat() - value.lat) > SAME || Math.abs(c.lng() - value.lng) > SAME)) {
      map.panTo({ lat: value.lat, lng: value.lng });
    }
  }, [map, value.lat, value.lng]);

  // Dragging ends in `idle`: the centre is the new pin.
  useEffect(() => {
    if (!map || locked) return;
    const listener = map.addListener('idle', () => {
      target.current = null;
      const c = map.getCenter();
      const { value: v, onChange: change } = latest.current;
      if (!c || (Math.abs(c.lat() - v.lat) <= SAME && Math.abs(c.lng() - v.lng) <= SAME)) return;
      change({ ...v, lat: c.lat(), lng: c.lng() });
    });
    return () => listener.remove();
  }, [map, locked]);

  function onKeyDown(e: KeyboardEvent<HTMLDivElement>) {
    if (locked || !map) return;
    const next = nudge(target.current ?? value, e.key);
    if (!next) return;
    e.preventDefault();
    target.current = next;
    map.panTo(next);
  }

  return (
    <div
      className="vl-map"
      style={{ aspectRatio: '16 / 10' }}
      role="application"
      aria-roledescription="map"
      aria-label={
        locked
          ? `Pin for ${value.venueName || 'the activity'}, locked`
          : 'Pin position. Drag the map, or use the arrow keys to move the pin about 10 metres.'
      }
      tabIndex={locked ? undefined : 0}
      onKeyDown={onKeyDown}
    >
      <div ref={ref} style={{ position: 'absolute', inset: 0 }} />
      {status === 'loading' ? (
        <div className="vl-skel" style={{ position: 'absolute', inset: 0, borderRadius: 0 }} />
      ) : null}
      <Pin />
      {map && !locked ? <ZoomButtons map={map} /> : null}
      {map && !locked ? (
        <span className="vl-map-hint">
          <Chip tone="forest">Drag the map to place the pin</Chip>
        </span>
      ) : null}
    </div>
  );
}

function LocationTextFields({
  value,
  onChange,
  errors,
  locked,
}: {
  value: PickedLocation;
  onChange: (value: PickedLocation) => void;
  errors: { venueName?: string | null; addressText?: string | null };
  locked: boolean;
}) {
  return (
    <>
      <TextField
        label="Venue name"
        value={value.venueName}
        maxLength={200}
        required
        readOnly={locked}
        error={errors.venueName}
        onChange={(venueName) => onChange({ ...value, venueName })}
      />
      <TextField
        label="Address"
        value={value.addressText}
        maxLength={500}
        required
        readOnly={locked}
        error={errors.addressText}
        onChange={(addressText) => onChange({ ...value, addressText })}
      />
    </>
  );
}

/** FR-021: no Maps, so the host types the place, and the pin as coordinates from any map app. */
function ManualLocation({
  value,
  onChange,
  errors,
  locked,
}: {
  value: PickedLocation | null;
  onChange: (value: PickedLocation | null) => void;
  errors: { location?: string | null; venueName?: string | null; addressText?: string | null };
  locked: boolean;
}) {
  const [coords, setCoords] = useState(() => ({
    lat: value ? String(value.lat) : '',
    lng: value ? String(value.lng) : '',
  }));
  const current: PickedLocation = value ?? {
    placeId: null,
    venueName: '',
    addressText: '',
    lat: NaN,
    lng: NaN,
  };
  function setCoord(which: 'lat' | 'lng', raw: string) {
    const next = { ...coords, [which]: raw };
    setCoords(next);
    const lat = parseCoord(next.lat, 90);
    const lng = parseCoord(next.lng, 180);
    onChange({ ...current, lat: lat ?? NaN, lng: lng ?? NaN });
  }
  const latError = coords.lat !== '' && parseCoord(coords.lat, 90) === null;
  const lngError = coords.lng !== '' && parseCoord(coords.lng, 180) === null;
  return (
    <div className="vl-picker">
      <MapView state="failed" ratio="16 / 10" />
      <TextField
        label="Venue name"
        value={current.venueName}
        maxLength={200}
        required
        readOnly={locked}
        error={errors.venueName}
        onChange={(venueName) => onChange({ ...current, venueName })}
      />
      <TextField
        label="Address"
        value={current.addressText}
        maxLength={500}
        required
        readOnly={locked}
        error={errors.addressText}
        onChange={(addressText) => onChange({ ...current, addressText })}
      />
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)' }}>
        <TextField
          label="Latitude"
          value={coords.lat}
          inputMode="decimal"
          placeholder="-1.2921"
          readOnly={locked}
          error={latError ? 'Between -90 and 90' : null}
          onChange={(v) => setCoord('lat', v)}
        />
        <TextField
          label="Longitude"
          value={coords.lng}
          inputMode="decimal"
          placeholder="36.8219"
          readOnly={locked}
          error={lngError ? 'Between -180 and 180' : null}
          onChange={(v) => setCoord('lng', v)}
        />
      </div>
      <p className="vl-field-help" style={{ margin: 0 }}>
        {errors.location ?? 'Copy the pin’s coordinates from any map app.'}
      </p>
      <p className="vl-public-note" style={{ margin: 0 }}>
        <Icon name="info" />
        {PIN_PUBLIC_NOTE}
      </p>
    </div>
  );
}

function parseCoord(raw: string, limit: number): number | null {
  if (!/^\s*-?\d+(\.\d+)?\s*$/.test(raw)) return null;
  const n = Number(raw);
  return Math.abs(n) <= limit ? n : null;
}

export interface CommunityMapPoint {
  id: string;
  lat: number;
  lng: number;
  /** The marker's text, e.g. "3 left". */
  label: string;
  title: string;
}

/**
 * C1's map (FR-020): one marker per activity with spots, nearby ones clustered (a tap zooms in), a
 * tap on a marker opens its summary card. If Maps is unavailable, the list is offered instead.
 */
export function CommunityMapLive({
  points,
  renderCard,
  onShowList,
  ratio = '16 / 10',
}: {
  points: CommunityMapPoint[];
  renderCard: (id: string) => ReactNode;
  onShowList: () => void;
  ratio?: string;
}) {
  const { ref, status, map } = useGoogleMap({ center: points[0] ?? DEFAULT_CENTER, zoom: 12 });
  const layer = useOverlay(map, points);
  const [selected, setSelected] = useState<string | null>(null);
  const boundsKey = JSON.stringify(points.map((p) => [p.lat, p.lng]));

  useEffect(() => {
    const positions = JSON.parse(boundsKey) as [number, number][];
    if (!map || positions.length < 2) return;
    const bounds = new google.maps.LatLngBounds();
    for (const [lat, lng] of positions) bounds.extend({ lat, lng });
    map.fitBounds(bounds, 48);
  }, [map, boundsKey]);

  useEffect(() => {
    if (!map) return;
    const listener = map.addListener('click', () => setSelected(null));
    return () => listener.remove();
  }, [map]);

  if (status === 'unavailable') {
    return (
      <div
        className="vl-map"
        style={{ aspectRatio: ratio }}
        role="region"
        aria-label="Map of upcoming activities"
      >
        <div className="vl-map-placeholder">
          <Icon name="map" />
          <span>The map didn’t load.</span>
          <Button variant="secondary" small icon="list" onClick={onShowList}>
            Show the list instead
          </Button>
        </div>
      </div>
    );
  }

  const clusters: Cluster[] = layer ? clusterPoints(layer.pixels) : [];
  function zoomInto(cluster: Cluster) {
    if (!map) return;
    const bounds = new google.maps.LatLngBounds();
    for (const i of cluster.members) bounds.extend(points[i]!);
    const span = bounds.toSpan();
    // Activities at the same spot never separate: open the first instead of zooming forever.
    if (span.lat() < 1e-5 && span.lng() < 1e-5) setSelected(points[cluster.members[0]!]!.id);
    else map.fitBounds(bounds, 64);
  }

  return (
    <div
      className="vl-map"
      style={{ aspectRatio: ratio }}
      role="region"
      aria-label="Map of upcoming activities"
    >
      <div ref={ref} style={{ position: 'absolute', inset: 0 }} />
      {status === 'loading' ? (
        <div className="vl-skel" style={{ position: 'absolute', inset: 0, borderRadius: 0 }} />
      ) : null}
      {layer
        ? createPortal(
            clusters.map((c) => {
              if (c.members.length > 1) {
                return (
                  <button
                    key={c.members.join(',')}
                    type="button"
                    className="vl-map-marker is-cluster"
                    style={{ left: c.x, top: c.y }}
                    aria-label={`${c.members.length} activities here. Zoom in`}
                    onClick={() => zoomInto(c)}
                  >
                    {c.members.length}
                  </button>
                );
              }
              const p = points[c.members[0]!]!;
              return (
                <button
                  key={p.id}
                  type="button"
                  className={cx('vl-map-marker', selected === p.id && 'is-selected')}
                  style={{ left: c.x, top: c.y }}
                  aria-label={`${p.title}, ${p.label}`}
                  aria-pressed={selected === p.id}
                  onClick={() => setSelected(p.id)}
                >
                  {p.label}
                </button>
              );
            }),
            layer.pane,
          )
        : null}
      {map ? <ZoomButtons map={map} /> : null}
      {selected ? <div className="vl-map-card">{renderCard(selected)}</div> : null}
    </div>
  );
}
