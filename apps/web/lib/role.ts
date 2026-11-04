// The Host / Booker toggle (S5 FR-011; PRD W1) changes the interface, never permissions. The choice is
// remembered in a plain first-party cookie so the next visit opens in the same mode.
import type { Role } from '@/components/chrome';

export const ROLE_COOKIE = 'velio_role';
const MAX_AGE = 60 * 60 * 24 * 365;

export function parseRole(value: string | undefined): Role {
  return value === 'host' ? 'host' : 'booker';
}

/** Host pages are always Host mode; elsewhere the remembered choice applies. */
export function roleFor(pathname: string, saved: Role): Role {
  return pathname.startsWith('/host') ? 'host' : saved;
}

export function saveRole(role: Role): void {
  const secure = window.location.protocol === 'https:' ? '; secure' : '';
  document.cookie = `${ROLE_COOKIE}=${role}; max-age=${MAX_AGE}; path=/; samesite=lax${secure}`;
}
