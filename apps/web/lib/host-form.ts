// H2 create and edit (S5 FR-033, FR-034): the form's state, its copy-deck validation, and the request
// bodies. Kept free of React so the rules are unit-tested on their own.
import type { ActivityCreate, ActivityPatch, PublicActivity } from '@velio/contracts';
import type { PickedLocation } from '@/components/maps-live';
import type { LatLng } from './maps/geo';

export const MEETING_POINT_MAX = 140;
export const CAPACITY_MAX = 100_000;

export interface HostForm {
  communitySlug: string;
  title: string;
  description: string;
  /** `YYYY-MM-DD` and `HH:mm`, wall-clock time in `timezone`. */
  date: string;
  time: string;
  timezone: string;
  location: PickedLocation | null;
  meetingPoint: string;
  /** As typed, in major units of the community's currency. */
  price: string;
  capacity: number;
  photoKey: string | null;
}

export type Field =
  | 'photo'
  | 'title'
  | 'date'
  | 'time'
  | 'timezone'
  | 'location'
  | 'venueName'
  | 'addressText'
  | 'price'
  | 'capacity';

export type FormErrors = Partial<Record<Field, string>>;

/**
 * Communities carry no currency, so each one prices in its country's (PRD Q11: Kenya, Tanzania,
 * Morocco). Unknown communities fall back to the first.
 */
const COMMUNITY: Record<string, { currency: string; center: LatLng }> = {
  'explore-kenya': { currency: 'KES', center: { lat: -1.2921, lng: 36.8219 } },
  'the-tanzania-experience': { currency: 'TZS', center: { lat: -3.3869, lng: 36.683 } },
  'the-medina-collective': { currency: 'MAD', center: { lat: 31.6295, lng: -7.9811 } },
};
const FALLBACK = COMMUNITY['explore-kenya']!;

export const communityCurrency = (slug: string) => (COMMUNITY[slug] ?? FALLBACK).currency;
export const communityCenter = (slug: string) => (COMMUNITY[slug] ?? FALLBACK).center;

export function isTimeZone(zone: string): boolean {
  if (!zone.trim()) return false;
  try {
    new Intl.DateTimeFormat('en', { timeZone: zone });
    return true;
  } catch {
    return false;
  }
}

/** The zone's wall clock at `at`, in UTC milliseconds, minus `at`: its offset in minutes. */
function offsetMinutes(zone: string, at: number): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: zone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(new Date(at));
  const get = (type: string) => Number(parts.find((p) => p.type === type)?.value);
  const wall = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour'), get('minute'), get('second'));
  return Math.round((wall - at) / 60_000);
}

/** `2026-12-05T17:30:00+03:00` for 17:30 on 5 December in `zone`; null when any part is missing. */
export function zonedToIso(date: string, time: string, zone: string): string | null {
  const d = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  const t = /^(\d{2}):(\d{2})$/.exec(time);
  if (!d || !t || !isTimeZone(zone)) return null;
  const wall = Date.UTC(Number(d[1]), Number(d[2]) - 1, Number(d[3]), Number(t[1]), Number(t[2]));
  // Twice, so a guess on the far side of a DST change settles on the offset in force at that time.
  const offset = offsetMinutes(zone, wall - offsetMinutes(zone, wall) * 60_000);
  const sign = offset < 0 ? '-' : '+';
  const abs = Math.abs(offset);
  const hh = String(Math.floor(abs / 60)).padStart(2, '0');
  const mm = String(abs % 60).padStart(2, '0');
  return `${date}T${time}:00${sign}${hh}:${mm}`;
}

/** The inverse, for the edit form: the date and time inputs' values in the activity's zone. */
export function isoToZoned(iso: string, zone: string): { date: string; time: string } {
  const at = Date.parse(iso);
  const local = new Date(at + offsetMinutes(zone, at) * 60_000).toISOString();
  return { date: local.slice(0, 10), time: local.slice(11, 16) };
}

function currencyDigits(currency: string): number {
  return (
    new Intl.NumberFormat('en', { style: 'currency', currency }).resolvedOptions().maximumFractionDigits ?? 2
  );
}

/** "3,500" → 350000 for KES; null when it isn't a positive amount the currency can hold. */
export function parsePrice(raw: string, currency: string): number | null {
  const text = raw.replace(/[\s,]/g, '');
  const digits = currencyDigits(currency);
  const m = /^(\d+)(?:\.(\d+))?$/.exec(text);
  if (!m || (m[2] && m[2].length > digits)) return null;
  const minor = Number(m[1]) * 10 ** digits + Number((m[2] ?? '').padEnd(digits, '0') || 0);
  return minor > 0 && Number.isSafeInteger(minor) ? minor : null;
}

/** The edit form's price field, from minor units. */
export function priceText(minor: number, currency: string): string {
  const digits = currencyDigits(currency);
  return new Intl.NumberFormat('en', { maximumFractionDigits: digits, useGrouping: true }).format(
    minor / 10 ** digits,
  );
}

/** Copy deck `host.spotsHelp`. */
export function spotsHelp(booked: number): string {
  return booked > 0
    ? `${booked} booked, so at least ${booked}. You can always add more.`
    : 'You can add spots later, never fewer than people booked.';
}

/** Copy deck `host.validationSummary`. */
export function summaryTitle(count: number, editing: boolean): string {
  const things = count === 1 ? '1 thing needs' : `${count} things need`;
  return `${things} fixing before you can ${editing ? 'save' : 'publish'}.`;
}

export interface ValidateOptions {
  editing: boolean;
  /** Date, time, zone and location are locked after the first booking and aren't checked. */
  locked: boolean;
  booked: number;
  currency: string;
  now: number;
}

/** Copy-deck errors (UI design §5.5 batch 3), keyed by field, in the form's order. */
export function validate(form: HostForm, o: ValidateOptions): FormErrors {
  const e: FormErrors = {};
  if (!form.photoKey) e.photo = 'Add a photo. It shows on the activity page and every invite.';
  if (!form.title.trim()) e.title = 'Add a title.';
  if (!o.locked) {
    const iso = zonedToIso(form.date, form.time, form.timezone);
    if (!form.date || (iso && Date.parse(iso) <= o.now)) e.date = 'Pick a date in the future.';
    if (!form.time) e.time = 'Pick a start time.';
    if (!isTimeZone(form.timezone)) e.timezone = 'Pick a time zone from the list.';
    const loc = form.location;
    if (!loc || !Number.isFinite(loc.lat) || !Number.isFinite(loc.lng)) {
      e.location = 'Search for a place, or drop a pin on the map.';
    } else {
      if (!loc.venueName.trim()) e.venueName = 'Add the venue name.';
      if (!loc.addressText.trim()) e.addressText = 'Add the address.';
    }
  }
  if (!o.editing && parsePrice(form.price, o.currency) === null) e.price = 'Enter the price per person.';
  const floor = Math.max(1, o.booked);
  if (!Number.isInteger(form.capacity) || form.capacity < floor) {
    e.capacity = o.booked > 0 ? `${o.booked} booked, so at least ${o.booked}.` : 'At least 1 spot.';
  } else if (form.capacity > CAPACITY_MAX) {
    e.capacity = `At most ${CAPACITY_MAX.toLocaleString('en')} spots.`;
  }
  return e;
}

function locationBody(form: HostForm): ActivityCreate['location'] {
  const loc = form.location!;
  return {
    placeId: loc.placeId,
    venueName: loc.venueName.trim(),
    addressText: loc.addressText.trim(),
    lat: loc.lat,
    lng: loc.lng,
    meetingPoint: form.meetingPoint.trim() || null,
  };
}

/** Only call after `validate` returns no errors. */
export function createBody(form: HostForm): ActivityCreate {
  const currency = communityCurrency(form.communitySlug);
  return {
    communitySlug: form.communitySlug,
    title: form.title.trim(),
    description: form.description.trim(),
    startsAt: zonedToIso(form.date, form.time, form.timezone)!,
    timezone: form.timezone,
    location: locationBody(form),
    priceMinor: parsePrice(form.price, currency)!,
    currency,
    capacity: form.capacity,
    ...(form.photoKey ? { photoKey: form.photoKey } : {}),
  };
}

/** The changed fields only; never the locked ones, which the API would refuse (`location_locked`). */
export function patchBody(form: HostForm, initial: HostForm, locked: boolean): ActivityPatch {
  const patch: ActivityPatch = {};
  if (form.title.trim() !== initial.title) patch.title = form.title.trim();
  if (form.description.trim() !== initial.description) patch.description = form.description.trim();
  if (form.capacity !== initial.capacity) patch.capacity = form.capacity;
  if (form.photoKey !== initial.photoKey) patch.photoKey = form.photoKey;
  if (!locked) {
    const startsAt = zonedToIso(form.date, form.time, form.timezone)!;
    if (startsAt !== zonedToIso(initial.date, initial.time, initial.timezone)) patch.startsAt = startsAt;
    if (form.timezone !== initial.timezone) patch.timezone = form.timezone;
    const location = locationBody(form);
    if (JSON.stringify(location) !== JSON.stringify(locationBody(initial))) patch.location = location;
  }
  return patch;
}

/** `/photos/<key>` → `<key>`. */
export function photoKeyFromUrl(url: string | null): string | null {
  return url?.startsWith('/photos/') ? url.slice('/photos/'.length) : null;
}

/** The edit form's starting values, from the public snapshot (the host's view adds nothing H2 needs). */
export function formFromActivity(a: PublicActivity): HostForm {
  return {
    communitySlug: a.community.slug,
    title: a.title,
    description: a.description,
    ...isoToZoned(a.startsAt, a.timezone),
    timezone: a.timezone,
    location: {
      placeId: a.location.placeId,
      venueName: a.location.venueName,
      addressText: a.location.addressText,
      lat: a.location.lat,
      lng: a.location.lng,
    },
    meetingPoint: a.location.meetingPoint ?? '',
    price: priceText(a.priceMinor, a.currency),
    capacity: a.capacity,
    photoKey: photoKeyFromUrl(a.photoUrl),
  };
}

/** "Amara O.", as the API shows a person publicly (PRD Q12). */
export function shortName(displayName: string): string {
  const parts = displayName.trim().split(/\s+/);
  const first = parts[0] ?? '';
  if (parts.length < 2) return first;
  return `${first} ${Array.from(parts[parts.length - 1]!)[0]!.toUpperCase()}.`;
}
