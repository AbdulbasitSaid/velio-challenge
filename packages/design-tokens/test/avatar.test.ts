import { describe, expect, test } from 'bun:test';
import fixtures from '../fixtures/avatar.json';
import { avatarColor, avatarIndex, initials } from '../src/avatar';

describe('avatarIndex', () => {
  test.each(fixtures)('$seed → $index', ({ seed, index }) => {
    expect(avatarIndex(seed)).toBe(index);
  });

  test('colour follows the palette order', () => {
    expect(avatarColor('a')).toBe('lime');
    expect(avatarColor('')).toBe('sky');
  });
});

describe('initials', () => {
  test.each([
    ['Tunde Adeyemi', 'TA'],
    ['Tunde A.', 'TA'],
    ['zainab', 'Z'],
    ['  Kofi  Mensah  Jr ', 'KJ'],
    ['', '?'],
  ])('%s → %s', (name, expected) => {
    expect(initials(name)).toBe(expected);
  });
});
