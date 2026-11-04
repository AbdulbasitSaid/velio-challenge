import type { InviteView } from '@velio/contracts';

export const ID = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
const person = { id: ID, shortName: 'Tunde A.', avatarSeed: ID };

export function inviteView(
  over: Partial<InviteView> = {},
  activity: Partial<InviteView['activity']> = {},
): InviteView {
  return {
    code: 'K7PQ2N',
    rail: 'vouch',
    status: 'claimable',
    pausedReason: null,
    inviter: person,
    note: null,
    claimedByViewer: false,
    ...over,
    activity: {
      id: ID,
      title: 'Sunset Kayaking',
      description: 'Two hours on the lake.',
      photoUrl: null,
      startsAt: '2026-12-14T14:30:00Z',
      timezone: 'Africa/Nairobi',
      priceMinor: 350000,
      currency: 'KES',
      capacity: 14,
      spotsLeft: 6,
      version: 3,
      status: 'open',
      bookingsPaused: false,
      host: { ...person, shortName: 'Amara W.' },
      community: { slug: 'explore-kenya', name: 'Explore Kenya' },
      members: { count: 1, preview: [person] },
      location: {
        placeId: null,
        venueName: 'Boat Club',
        addressText: 'Moi South Lake Rd',
        lat: -0.7,
        lng: 36.4,
        meetingPoint: null,
        staticMapUrl: null,
        directionsUrl: 'https://www.google.com/maps/dir/?api=1&destination=-0.7,36.4',
      },
      viewer: null,
      ...activity,
    },
  };
}
