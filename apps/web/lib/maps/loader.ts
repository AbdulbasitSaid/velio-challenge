// One shared Google Maps loader (S5 §4.10): the script loads once, on first use, never on page load
// (NFR-004). Any failure (no key, the script blocked, the key rejected) reads as "unavailable", and
// every caller falls back to the address (PRD A7, FR-021).
import { importLibrary, setOptions } from '@googlemaps/js-api-loader';

/** Referrer-restricted and public by nature (SEC-005); inlined at build time. */
const KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY ?? '';

export type MapsStatus = 'loading' | 'ready' | 'unavailable';

let configured = false;
let authFailed = false;
const authListeners = new Set<() => void>();

export function mapsConfigured(): boolean {
  return KEY !== '';
}

/** A rejected key loads the script but renders nothing; Google reports it only through this global. */
function watchAuthFailure() {
  const w = window as Window & { gm_authFailure?: () => void };
  w.gm_authFailure = () => {
    authFailed = true;
    for (const listener of authListeners) listener();
  };
}

/** Called when Google rejects the key after the script loaded. Returns an unsubscribe function. */
export function onMapsAuthFailure(listener: () => void): () => void {
  if (authFailed) queueMicrotask(listener);
  authListeners.add(listener);
  return () => authListeners.delete(listener);
}

export async function loadMaps(): Promise<{
  maps: google.maps.MapsLibrary;
  core: google.maps.CoreLibrary;
}> {
  if (!KEY || authFailed) throw new Error('maps unavailable');
  if (!configured) {
    configured = true;
    watchAuthFailure();
    setOptions({ key: KEY, v: 'weekly' });
  }
  const [maps, core] = await Promise.all([importLibrary('maps'), importLibrary('core')]);
  return { maps, core };
}

export async function loadPlaces(): Promise<google.maps.PlacesLibrary> {
  await loadMaps();
  return importLibrary('places');
}
