import { randomInt } from 'node:crypto';
import { INVITE_CODE_ALPHABET } from '@velio/contracts';

const CODE = new RegExp(`^[${INVITE_CODE_ALPHABET}]{6}$`);

/** 6 characters; `randomInt` draws without modulo bias (PRD I3). */
export function newInviteCode(): string {
  let code = '';
  for (let i = 0; i < 6; i++) code += INVITE_CODE_ALPHABET[randomInt(INVITE_CODE_ALPHABET.length)];
  return code;
}

/**
 * Typed codes are forgiving: spaces and hyphens are dropped and letters upper-cased. Returns
 * undefined when the result can't be a code, so it's rejected without a lookup.
 */
export function normaliseCode(raw: string): string | undefined {
  const code = raw.replace(/[\s-]+/g, '').toUpperCase();
  return CODE.test(code) ? code : undefined;
}

export const inviteLink = (baseUrl: string, code: string) => `${baseUrl}/i/${code}`;
