import { describe, expect, test } from 'bun:test';
import { ApiError } from '../../src/errors';
import { contactHash, normaliseContact } from '../../src/modules/identity/contact';
import { shortName } from '../../src/modules/identity/people';

// V-ID-1 (FR-009)
describe('normaliseContact', () => {
  const cases: [string, string | undefined, string][] = [
    ['Zainab@Example.com ', undefined, 'zainab@example.com'],
    ['  ZAINAB@EXAMPLE.COM', undefined, 'zainab@example.com'],
    ['+254 712 345 678', undefined, '+254712345678'],
    ['+254712345678', undefined, '+254712345678'],
    ['0712 345 678', 'KE', '+254712345678'],
    ['0712-345-678', 'KE', '+254712345678'],
    ['+44 7911 123456', undefined, '+447911123456'],
    ['07911 123456', 'GB', '+447911123456'],
  ];

  for (const [input, country, expected] of cases) {
    test(`${JSON.stringify(input)}${country ? ` (${country})` : ''} → ${expected}`, () => {
      expect(normaliseContact(input, country).value).toBe(expected);
    });
  }

  const invalid: [string, string | undefined][] = [
    ['+44 7700 900123', undefined], // Ofcom's reserved fictional range
    ['not a contact', undefined],
    ['zainab@', undefined],
    ['@example.com', undefined],
    ['0712345678', undefined], // national format with no country hint
    ['+254 12', undefined],
    ['', undefined],
  ];

  for (const [input, country] of invalid) {
    test(`${JSON.stringify(input)} → invalid_contact`, () => {
      try {
        normaliseContact(input, country);
        throw new Error('expected invalid_contact');
      } catch (err) {
        expect(err).toBeInstanceOf(ApiError);
        expect((err as ApiError).code).toBe('invalid_contact');
      }
    });
  }

  test('formats of one contact hash the same; different peppers differ', () => {
    const a = contactHash('pepper-a', normaliseContact('+254 712 345 678'));
    const b = contactHash('pepper-a', normaliseContact('0712345678', 'KE'));
    const c = contactHash('pepper-b', normaliseContact('+254712345678'));
    expect(a.equals(b)).toBe(true);
    expect(a.equals(c)).toBe(false);
    expect(a.length).toBe(32);
  });
});

describe('shortName (PRD Q12)', () => {
  test.each([
    ['Tunde Adeyemi', 'Tunde A.'],
    ['Amara Ngozi Okafor', 'Amara O.'],
    ['  zainab   bello ', 'zainab B.'],
    ['Cher', 'Cher'],
  ])('%p → %p', (input, expected) => {
    expect(shortName(input)).toBe(expected);
  });
});
