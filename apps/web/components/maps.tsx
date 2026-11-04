// Map surfaces from the approved design system. T10 replaces the representative art with Google Maps
// (static image, interactive map, picker, community map); the fallback states and copy are final.
import type { ReactNode } from 'react';
import { Button, Chip, cx, Icon, TextField } from './primitives';

export type MapState = 'static' | 'interactive' | 'dragging' | 'loading' | 'failed' | 'offline';

function MapArt({ variant = 'lake' }: { variant?: 'lake' | 'coast' }) {
  const road = (d: string, w: number) => (
    <path d={d} style={{ stroke: 'var(--map-road)', strokeWidth: w, fill: 'none' }} />
  );
  return (
    <svg className="vl-map-art" viewBox="0 0 400 225" preserveAspectRatio="xMidYMid slice" aria-hidden>
      <rect width={400} height={225} style={{ fill: 'var(--map-land)' }} />
      {variant === 'coast' ? (
        <path
          d="M260 0 C250 60 290 110 270 160 C255 200 290 225 300 225 L400 225 L400 0Z"
          style={{ fill: 'var(--map-water)' }}
        />
      ) : (
        <path
          d="M40 150 C30 110 80 90 120 100 C160 108 170 140 150 170 C130 200 60 200 40 150Z"
          style={{ fill: 'var(--map-water)' }}
        />
      )}
      <path
        d="M280 20 C320 10 360 40 350 70 C340 100 290 95 275 70 C265 50 262 26 280 20Z"
        style={{ fill: 'var(--map-park)' }}
      />
      {road('M0 60 L400 40', 7)}
      {road('M180 0 C190 80 200 140 240 225', 9)}
      {road('M0 190 C120 170 220 180 400 150', 5)}
      {road('M90 0 L120 225 M300 225 L330 120 L400 110', 3)}
    </svg>
  );
}

function Pin() {
  return (
    <svg className="vl-map-pin" viewBox="0 0 36 46" aria-hidden style={{ left: '50%', top: '52%' }}>
      <path d="M18 45s15-14.5 15-27A15 15 0 0 0 3 18c0 12.5 15 27 15 27z" style={{ fill: 'var(--forest)' }} />
      <circle cx={18} cy={18} r={6.5} style={{ fill: 'var(--lime)' }} />
    </svg>
  );
}

function Zoom() {
  return (
    <div className="vl-map-controls">
      <button className="vl-iconbtn" type="button" aria-label="Zoom in">
        <Icon name="plus" />
      </button>
      <button className="vl-iconbtn" type="button" aria-label="Zoom out">
        <Icon name="minus" />
      </button>
    </div>
  );
}

export function MapView({
  state = 'static',
  venue,
  label,
  ratio,
  tapHint,
  art,
  staticMapUrl,
  children,
}: {
  state?: MapState;
  venue?: string;
  label?: string;
  ratio?: string;
  tapHint?: boolean;
  art?: 'lake' | 'coast';
  /** Signed Google Static Maps URL from the snapshot (S6). Without it the representative art shows. */
  staticMapUrl?: string | null;
  children?: ReactNode;
}) {
  const blank = state === 'failed' || state === 'offline' || state === 'loading';
  return (
    <div
      className="vl-map"
      role="img"
      aria-label={label ?? `Map of ${venue ?? 'the activity location'}`}
      style={ratio ? { aspectRatio: ratio } : undefined}
    >
      {blank ? null : staticMapUrl && state === 'static' ? (
        // eslint-disable-next-line @next/next/no-img-element -- signed Google URL; no-referrer keeps codes out of Referer
        <img className="vl-map-art" src={staticMapUrl} alt="" loading="lazy" referrerPolicy="no-referrer" />
      ) : (
        <MapArt variant={art} />
      )}
      {!blank && !staticMapUrl ? <Pin /> : null}
      {state === 'interactive' || state === 'dragging' ? <Zoom /> : null}
      {state === 'static' && tapHint ? (
        <span className="vl-map-hint">
          <Chip tone="outline" icon="map">
            Tap to explore
          </Chip>
        </span>
      ) : null}
      {state === 'dragging' ? (
        <span className="vl-map-hint">
          <Chip tone="forest">Drag the map to place the pin</Chip>
        </span>
      ) : null}
      {state === 'loading' ? (
        <div className="vl-skel" style={{ position: 'absolute', inset: 0, borderRadius: 0 }} />
      ) : null}
      {state === 'failed' ? (
        <div className="vl-map-placeholder">
          <Icon name="map" />
          <span>The map didn’t load. The address below still works.</span>
        </div>
      ) : null}
      {state === 'offline' ? (
        <div className="vl-map-placeholder">
          <Icon name="offline" />
          <span>Map unavailable offline</span>
        </div>
      ) : null}
      {blank ? null : <span className="vl-map-attrib">Google</span>}
      {children}
    </div>
  );
}

export function LocationBlock({
  venue,
  address,
  meetingPoint,
  directionsUrl,
  mapState = 'static',
  staticMapUrl,
  title = 'Where',
  map = true,
  onCopy,
  tapHint,
  ratio,
}: {
  venue: string;
  address: string;
  meetingPoint?: string | null;
  directionsUrl: string;
  mapState?: MapState;
  staticMapUrl?: string | null;
  title?: string | false;
  /** False hides the map (A7: no key, or the static map is unavailable). */
  map?: boolean;
  onCopy?: () => void;
  tapHint?: boolean;
  ratio?: string;
}) {
  return (
    <section className="vl-location" aria-label="Location">
      {title === false ? null : (
        <h3 style={{ margin: 0, font: '700 17px/24px var(--font-body)' }}>{title}</h3>
      )}
      {map ? (
        <MapView state={mapState} venue={venue} staticMapUrl={staticMapUrl} tapHint={tapHint} ratio={ratio} />
      ) : null}
      <div className="vl-location-text">
        <Icon name="pin" />
        <span>
          <span className="vl-location-venue">{venue}</span>
          <span className="vl-location-address">{address}</span>
        </span>
      </div>
      {meetingPoint ? (
        <div className="vl-meeting">
          <Icon name="flag" />
          <span>
            <strong>Meeting point: </strong>
            {meetingPoint}
          </span>
        </div>
      ) : null}
      <div className="vl-location-actions">
        <Button variant="secondary" small icon="directions" href={directionsUrl} external>
          Get directions
        </Button>
        {onCopy ? (
          <Button variant="quiet" small icon="copy" onClick={onCopy}>
            Copy address
          </Button>
        ) : null}
      </div>
    </section>
  );
}

export const PIN_PUBLIC_NOTE =
  'The pin, address and meeting point are public. Anyone who sees this activity can see exactly where it is. They lock once someone books.';

/** Visual states of the H2 picker. T10 drives them from Places and the map. */
export function LocationPicker({
  state = 'empty',
  query = '',
  results = [],
  venue,
}: {
  state?: 'empty' | 'results' | 'pinned' | 'noresults' | 'unavailable';
  query?: string;
  results?: { name: string; sub: string }[];
  venue?: string;
}) {
  return (
    <div className="vl-picker">
      <TextField
        label="Location"
        search
        defaultValue={query}
        placeholder="Search for a place or address"
        id="loc-search"
        error={
          state === 'noresults'
            ? `No places match “${query}”. Check the spelling, or drop a pin on the map.`
            : state === 'unavailable'
              ? 'Place search isn’t available right now. Drop a pin on the map instead.'
              : null
        }
      />
      {state === 'results' ? (
        <div className="vl-pickres" role="listbox" aria-label="Places">
          {results.map((r, i) => (
            <button key={i} type="button" role="option" aria-selected={i === 0}>
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
      {state === 'empty' || state === 'results' ? null : (
        <MapView state={state === 'unavailable' ? 'failed' : 'dragging'} venue={venue} ratio="16 / 10" />
      )}
      <p className="vl-public-note" style={{ margin: 0 }}>
        <Icon name="info" />
        {PIN_PUBLIC_NOTE}
      </p>
    </div>
  );
}

export interface CommunityMapItem {
  x: number;
  y: number;
  label?: string;
  title?: string;
  cluster?: number;
}

export function CommunityMap({
  items = [],
  selected,
  card,
  ratio = '16 / 10',
  onSelect,
}: {
  items?: CommunityMapItem[];
  selected?: number;
  card?: ReactNode;
  ratio?: string;
  onSelect?: (index: number) => void;
}) {
  return (
    <div
      className="vl-map"
      style={{ aspectRatio: ratio }}
      role="region"
      aria-label="Map of upcoming activities"
    >
      <MapArt />
      {items.map((it, i) => (
        <button
          key={i}
          type="button"
          className={cx('vl-map-marker', it.cluster ? 'is-cluster' : false, selected === i && 'is-selected')}
          style={{ left: `${it.x}%`, top: `${it.y}%` }}
          aria-label={it.cluster ? `${it.cluster} activities here` : `${it.title ?? 'Activity'}, ${it.label}`}
          onClick={onSelect ? () => onSelect(i) : undefined}
        >
          {it.cluster ? String(it.cluster) : it.label}
        </button>
      ))}
      <Zoom />
      {selected != null && card ? (
        <div className="vl-map-card">{card}</div>
      ) : (
        <span className="vl-map-attrib">Google</span>
      )}
    </div>
  );
}
