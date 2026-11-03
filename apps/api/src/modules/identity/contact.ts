import { createHmac } from 'node:crypto';
// The "max" metadata validates numbers exactly; the default only checks their length.
import { parsePhoneNumberFromString, type CountryCode } from 'libphonenumber-js/max';
import { ApiError } from '../../errors';

export interface NormalisedContact {
  kind: 'email' | 'phone';
  /** Lowercased email, or phone in E.164. */
  value: string;
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const INVALID = 'Enter a valid email address or phone number.';

/**
 * Normalises a contact so one person maps to one user (R5): emails are trimmed and lowercased,
 * phones become E.164. `country` reads numbers written without a country code ("0712…").
 */
export function normaliseContact(raw: string, country?: string): NormalisedContact {
  const trimmed = raw.trim();
  if (trimmed.includes('@')) {
    const email = trimmed.toLowerCase();
    if (!EMAIL.test(email)) throw new ApiError('invalid_contact', INVALID);
    return { kind: 'email', value: email };
  }
  const phone = parsePhoneNumberFromString(trimmed, country as CountryCode | undefined);
  if (!phone?.isValid()) throw new ApiError('invalid_contact', INVALID);
  return { kind: 'phone', value: phone.number };
}

/**
 * HMAC-SHA256 keyed by a server secret. A per-row salt would make matching impossible, so the
 * "salted hash" of the MVP plan is a keyed hash (S1 PLANNING §4.4).
 */
export function contactHash(pepper: string, normalised: NormalisedContact): Buffer {
  return createHmac('sha256', pepper).update(normalised.value).digest();
}
