import { render, screen } from '@testing-library/react';
import { ApiRequestError } from '@/lib/api/client';
import { claimKey, claimOutcome, clearClaimKey } from '@/components/invite/claim-form';

const err = (code: ConstructorParameters<typeof ApiRequestError>[1], status = 409) =>
  new ApiRequestError(status, code, code);

describe('claim rejection mapping (V-CLM-3)', () => {
  test.each([
    ['invite_expired', 'back'],
    ['invite_paused', 'back'],
    ['already_claimed', 'back'],
    ['activity_started', 'back'],
    ['forbidden', 'back'],
    ['already_booked', 'done'],
    ['invalid_contact', 'field'],
    ['validation_failed', 'field'],
    ['sold_out', 'banner'],
    ['rate_limited', 'banner'],
    ['bookings_paused', 'banner'],
    ['booking_removed', 'banner'],
    ['internal', 'banner'],
    ['network', 'banner'],
  ] as const)('%s → %s', (code, kind) => {
    expect(claimOutcome(err(code), 'K7PQ2N').kind).toBe(kind);
  });

  test('server errors offer a retry with the same key; sold out does not', () => {
    const server = claimOutcome(err('internal', 500), 'K7PQ2N');
    expect(server).toMatchObject({
      retry: true,
      final: false,
      title: 'We couldn’t confirm your spot. Nothing was booked.',
    });
    const soldOut = claimOutcome(err('sold_out'), 'K7PQ2N');
    expect(soldOut).toMatchObject({ retry: false, final: true, title: 'Someone just took the last spot.' });
    if (soldOut.kind !== 'banner') throw new Error();
    render(<>{soldOut.body}</>);
    expect(screen.getByRole('link', { name: 'See other dates and activities' })).toHaveAttribute(
      'href',
      '/i/K7PQ2N',
    );
  });

  test('field errors name the field', () => {
    expect(claimOutcome(err('invalid_contact', 400), 'X')).toEqual({ kind: 'field', field: 'contact' });
    expect(claimOutcome(err('validation_failed', 400), 'X')).toEqual({ kind: 'field', field: 'name' });
  });
});

describe('idempotency key (V-CLM-2)', () => {
  afterEach(() => sessionStorage.clear());

  test('one key per code, reused until cleared, never holding the contact', () => {
    const first = claimKey('K7PQ2N');
    expect(claimKey('K7PQ2N')).toBe(first); // retry or reload
    expect(claimKey('ABCDEF')).not.toBe(first); // another invite
    expect(Object.values(sessionStorage)).not.toContain('+254712345678');
    clearClaimKey('K7PQ2N');
    expect(claimKey('K7PQ2N')).not.toBe(first); // a new attempt after a final outcome
  });
});
