import { ID, inviteView as view } from './fixtures';
import { selectScreen } from '@/lib/invite-screen';

const booking = (status: 'confirmed' | 'removed') => ({ id: ID, planId: ID, status });

test.each([
  ['claimable vouch', view(), { kind: 'open', block: null }],
  ['claimable public', view({ rail: 'public' }), { kind: 'open', block: null }],
  ['claimed by viewer', view({ status: 'claimed', claimedByViewer: true }), { kind: 'claimed-own' }],
  ['claimed by someone else', view({ status: 'claimed' }), { kind: 'claimed-other' }],
  ['expired', view({ status: 'expired' }), { kind: 'expired' }],
  ['started (snapshot ahead of invite)', view({}, { status: 'started' }), { kind: 'expired' }],
  ['paused link', view({ rail: 'public', status: 'paused', pausedReason: 'auto' }), { kind: 'paused' }],
  ['sold out', view({}, { spotsLeft: 0, status: 'sold_out' }), { kind: 'sold-out' }],
  ['bookings paused', view({}, { bookingsPaused: true }), { kind: 'open', block: 'bookings-paused' }],
  [
    'viewer already going',
    view({}, { viewer: { isHost: false, booking: booking('confirmed') } }),
    { kind: 'open', block: 'already-going' },
  ],
  [
    'viewer already going on a sold-out activity',
    view({}, { spotsLeft: 0, status: 'sold_out', viewer: { isHost: false, booking: booking('confirmed') } }),
    { kind: 'open', block: 'already-going' },
  ],
  [
    'viewer removed by host',
    view({}, { viewer: { isHost: false, booking: booking('removed') } }),
    { kind: 'open', block: null },
  ],
  [
    'viewer is the host',
    view({}, { viewer: { isHost: true, booking: null } }),
    { kind: 'open', block: 'host' },
  ],
] as const)('%s', (_, v, expected) => {
  expect(selectScreen(v)).toEqual(expected);
});

test('live spots move between open and sold out without reload', () => {
  const v = view();
  expect(selectScreen(v, 0)).toEqual({ kind: 'sold-out' });
  expect(selectScreen(view({}, { spotsLeft: 0, status: 'sold_out' }), 1)).toEqual({
    kind: 'open',
    block: null,
  });
});
