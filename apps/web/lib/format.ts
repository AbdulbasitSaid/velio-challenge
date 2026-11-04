// Display formatting with Intl only (no date library: S6 JS budget). Times are always shown in the
// activity's zone with the zone named (PRD: times in the activity's zone).
/** Same as contracts' INVITE_CODE_ALPHABET (a test keeps them equal); imported by value it would pull Zod in. */
export const CODE_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/** "Sat 14 Dec, 17:30" in the activity's zone. */
export function formatWhen(iso: string, timeZone: string): string {
  const d = new Date(iso);
  const day = new Intl.DateTimeFormat('en-GB', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    timeZone,
  }).format(d);
  return `${day.replace(',', '')}, ${formatTime(iso, timeZone)}`;
}

/** "Sat 14 Dec" in the activity's zone. */
export function formatDay(iso: string, timeZone: string): string {
  return new Intl.DateTimeFormat('en-GB', { weekday: 'short', day: 'numeric', month: 'short', timeZone })
    .format(new Date(iso))
    .replace(',', '');
}

/** "17:30" in the activity's zone. */
export function formatTime(iso: string, timeZone: string): string {
  return new Intl.DateTimeFormat('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone,
  }).format(new Date(iso));
}

/** "Nairobi time" from "Africa/Nairobi". */
export function zoneLabel(timeZone: string): string {
  const city = timeZone.split('/').pop() ?? timeZone;
  return `${city.replace(/_/g, ' ')} time`;
}

/** "KES 3,500", or "Free". Minor units per the currency's own digits. */
export function formatMoney(minor: number, currency: string): string {
  if (minor === 0) return 'Free';
  const digits =
    new Intl.NumberFormat('en', { style: 'currency', currency }).resolvedOptions().maximumFractionDigits ?? 2;
  const amount = minor / 10 ** digits;
  const number = new Intl.NumberFormat('en', {
    minimumFractionDigits: amount % 1 === 0 ? 0 : digits,
    maximumFractionDigits: digits,
  }).format(amount);
  return `${currency} ${number}`;
}

/** "Tunde" from "Tunde A." or "Tunde Adeyemi". */
export function firstName(name: string): string {
  return name.trim().split(/\s+/)[0] ?? name;
}

/** "June 2023" from "2023-06". */
export function monthYear(yyyyMm: string): string {
  const [y, m] = yyyyMm.split('-').map(Number);
  return new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric', timeZone: 'UTC' }).format(
    new Date(Date.UTC(y ?? 1970, (m ?? 1) - 1, 1)),
  );
}

export function spotsLabel(spotsLeft: number): string {
  if (spotsLeft <= 0) return 'Sold out';
  return spotsLeft === 1 ? '1 spot left' : `${spotsLeft} spots left`;
}

const CODE = new RegExp(`^[${CODE_ALPHABET}]{6}$`);

/** Like the API: spaces and hyphens dropped, upper-cased; undefined when it can't be a code. */
export function normaliseCode(raw: string): string | undefined {
  const code = decodeURIComponent(raw)
    .replace(/[\s-]+/g, '')
    .toUpperCase();
  return CODE.test(code) ? code : undefined;
}
