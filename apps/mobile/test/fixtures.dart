// Test data shaped like the API's responses (packages/contracts), parsed with the generated models.
import 'package:velio_api/velio_api.dart';

const activityId = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
const planId = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e01';

Map<String, dynamic> person(String id, String short) => {'id': id, 'shortName': short, 'avatarSeed': id};

Map<String, dynamic> member(String id, String short, String full) => {...person(id, short), 'displayName': full};

Map<String, dynamic> activityJson({
  int spotsLeft = 6,
  int version = 3,
  String status = 'open',
  bool bookingsPaused = false,
  Map<String, dynamic>? viewer,
}) => {
  'id': activityId,
  'title': 'Sunset Kayaking',
  'description': 'Two hours on Lake Naivasha as the sun drops.',
  'photoUrl': null,
  'startsAt': '2026-12-14T14:30:00.000Z',
  'timezone': 'Africa/Nairobi',
  'priceMinor': 350000,
  'currency': 'KES',
  'capacity': 14,
  'spotsLeft': spotsLeft,
  'version': version,
  'status': status,
  'bookingsPaused': bookingsPaused,
  'host': person('0190a6f2-0000-7000-8000-000000000001', 'Amara W.'),
  'community': {'slug': 'explore-kenya', 'name': 'Explore Kenya'},
  'members': {
    'count': 3,
    'preview': [
      person('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.'),
      person('0190a6f2-0000-7000-8000-000000000003', 'Imani K.'),
    ],
  },
  'location': {
    'placeId': null,
    'venueName': 'Lake Naivasha Boat Club',
    'addressText': 'Moi South Lake Rd, Naivasha, Kenya',
    'lat': -0.7667,
    'lng': 36.4333,
    'meetingPoint': 'Meet at the blue gate by the jetty, 15 minutes before',
    'staticMapUrl': null,
    'directionsUrl': 'https://www.google.com/maps/dir/?api=1&destination=-0.7667,36.4333',
  },
  'viewer': viewer,
};

InviteView inviteView({
  String rail = 'vouch',
  String status = 'claimable',
  bool claimedByViewer = false,
  String? pausedReason,
  Map<String, dynamic>? activity,
}) => InviteView.fromJson({
  'code': 'K7PQ2N',
  'rail': rail,
  'status': status,
  'pausedReason': pausedReason,
  'inviter': person('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.'),
  'note': 'Come along!',
  'claimedByViewer': claimedByViewer,
  'activity': activity ?? activityJson(),
});

Map<String, dynamic> planJson({String bookingStatus = 'confirmed', bool canInvite = true}) => {
  'id': planId,
  'activity': {
    'id': activityId,
    'title': 'Sunset Kayaking',
    'startsAt': '2026-12-14T14:30:00.000Z',
    'timezone': 'Africa/Nairobi',
  },
  'owner': member('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.', 'Tunde Adeyemi'),
  'members': [
    {
      'person': member('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.', 'Tunde Adeyemi'),
      'source': 'direct',
      'invitedBy': null,
      'joinedAt': '2026-12-02T10:00:00.000Z',
    },
    {
      'person': member('0190a6f2-0000-7000-8000-000000000009', 'Zainab O.', 'Zainab Okafor'),
      'source': 'vouch',
      'invitedBy': member('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.', 'Tunde Adeyemi'),
      'joinedAt': '2026-12-03T10:00:00.000Z',
    },
  ],
  'viewer': {
    'booking': {'id': '0190a6f2-0000-7000-8000-0000000000b1', 'ref': 'VLO-48213', 'status': bookingStatus},
    'canInvite': canInvite,
  },
  'invites': [
    {
      'id': '0190a6f2-0000-7000-8000-0000000000c1',
      'rail': 'vouch',
      'inviteeName': 'Wanjiru',
      'createdBy': member('0190a6f2-0000-7000-8000-000000000009', 'Zainab O.', 'Zainab Okafor'),
      'status': 'opened',
      'opens': 1,
      'claims': 0,
      'paused': false,
      'pausedReason': null,
      'createdAt': '2026-12-03T11:00:00.000Z',
      'code': 'H4XM9R',
      'link': 'https://depimls1pcvv4.cloudfront.net/i/H4XM9R',
      'note': null,
    },
  ],
};

// ---- S7b: communities, host lists and attendance ----

Map<String, dynamic> communityJson() => {
  'slug': 'explore-kenya',
  'name': 'Explore Kenya',
  'blurb': 'Weekend trips around Nairobi.',
  'coverPhotoUrl': null,
  'upcomingCount': 2,
};

Map<String, dynamic> cardJson({String id = activityId, int spotsLeft = 6, String status = 'open'}) => {
  ...activityJson(spotsLeft: spotsLeft, status: status),
  'id': id,
  'location': {'venueName': 'Lake Naivasha Boat Club', 'lat': -0.7667, 'lng': 36.4333},
};

Map<String, dynamic> communityPageJson({bool empty = false}) => {
  'community': communityJson(),
  'activities': empty
      ? <Object>[]
      : [cardJson(), cardJson(id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e10', spotsLeft: 0, status: 'sold_out')],
};

Map<String, dynamic> hostItemJson({int booked = 8, int marked = 0, int attended = 0, int spotsLeft = 6}) => {
  ...cardJson(spotsLeft: spotsLeft),
  'bookedCount': booked,
  'markedCount': marked,
  'attendedCount': attended,
};

Map<String, dynamic> hostListJson({bool empty = false}) => {
  'upcoming': empty ? <Object>[] : [hostItemJson(), hostItemJson(booked: 0, spotsLeft: 14)],
  'past': empty ? <Object>[] : [hostItemJson(marked: 5, attended: 5)],
};

Map<String, dynamic> attendeeJson(
  String n, {
  String source = 'direct',
  String status = 'confirmed',
  String? mark,
  String bookedAt = '2026-12-02T10:00:00.000Z',
  String planId = planId,
}) => {
  'bookingId': '0190a6f2-0000-7000-8000-0000000000a$n',
  'ref': 'VLO-1000$n',
  'status': status,
  'person': member('0190a6f2-0000-7000-8000-00000000010$n', 'Guest$n G.', 'Guest$n Gathoni'),
  'bookedAt': bookedAt,
  'source': source,
  'invitedBy': source == 'vouch' ? member('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.', 'Tunde Adeyemi') : null,
  'planId': planId,
  'mark': mark,
  'markedAt': null,
};

Map<String, dynamic> attendanceJson({bool started = false, bool empty = false}) => {
  'activity': {
    'id': activityId,
    'capacity': 14,
    'spotsLeft': 11,
    'version': 3,
    'startsAt': started ? '2026-11-04T10:00:00.000Z' : '2026-12-14T14:30:00.000Z',
    'timezone': 'Africa/Nairobi',
    'started': started,
  },
  'attendees': empty
      ? <Object>[]
      : [
          attendeeJson('1'),
          attendeeJson('2', source: 'vouch', bookedAt: '2026-12-03T10:00:00.000Z'),
          attendeeJson('3', source: 'public', status: 'removed', bookedAt: '2026-12-04T10:00:00.000Z'),
        ],
};
