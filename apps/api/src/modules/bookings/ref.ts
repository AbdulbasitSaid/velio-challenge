import { randomInt } from 'node:crypto';

/** The invite-code alphabet: no 0, 1, I, L or O (PRD business rules). */
export const REF_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/** `VLO-` plus 5 characters. `randomInt` draws without modulo bias. */
export function newBookingRef(): string {
  let ref = 'VLO-';
  for (let i = 0; i < 5; i++) ref += REF_ALPHABET[randomInt(REF_ALPHABET.length)];
  return ref;
}
