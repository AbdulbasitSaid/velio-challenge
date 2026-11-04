import {
  firstName,
  formatDay,
  formatMoney,
  formatWhen,
  monthYear,
  normaliseCode,
  spotsLabel,
  zoneLabel,
} from '@/lib/format';

test('times are shown in the activity zone', () => {
  // 14:30 UTC is 17:30 in Nairobi (UTC+3).
  expect(formatWhen('2026-12-14T14:30:00Z', 'Africa/Nairobi')).toBe('Mon 14 Dec, 17:30');
  expect(formatDay('2026-12-14T23:30:00Z', 'Africa/Nairobi')).toBe('Tue 15 Dec');
  expect(zoneLabel('Africa/Nairobi')).toBe('Nairobi time');
  expect(zoneLabel('America/Sao_Paulo')).toBe('Sao Paulo time');
});

test.each([
  [350000, 'KES', 'KES 3,500'],
  [1250, 'GBP', 'GBP 12.50'],
  [500, 'JPY', 'JPY 500'],
  [0, 'KES', 'Free'],
])('%i %s → %s', (minor, currency, expected) => {
  expect(formatMoney(minor, currency)).toBe(expected);
});

test('names, months, spots', () => {
  expect(firstName('Tunde A.')).toBe('Tunde');
  expect(monthYear('2023-06')).toBe('June 2023');
  expect(spotsLabel(0)).toBe('Sold out');
  expect(spotsLabel(1)).toBe('1 spot left');
  expect(spotsLabel(6)).toBe('6 spots left');
});

test.each([
  ['k7pq2n', 'K7PQ2N'],
  ['K7P-Q2N', 'K7PQ2N'],
  ['K7P%20Q2N', 'K7PQ2N'],
  ['K7PQ2', undefined],
  ['K7PQ2O', undefined], // O isn't in the alphabet
])('%s → %s', (raw, expected) => {
  expect(normaliseCode(raw)).toBe(expected);
});

test('code alphabet matches the contracts', async () => {
  const { INVITE_CODE_ALPHABET } = await import('@velio/contracts');
  const { CODE_ALPHABET } = await import('@/lib/format');
  expect(CODE_ALPHABET).toBe(INVITE_CODE_ALPHABET);
});
