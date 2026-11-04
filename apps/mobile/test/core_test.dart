// V-CODE-1, V-ERR-1, V-INV-1 (unit), V-DL-1 (routing part), V-API-1 (the generated models parse real
// responses captured from the deployed API, names replaced).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:velio/app/router.dart';
import 'package:velio/core/format.dart';
import 'package:velio/core/invite_logic.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';

Map<String, dynamic> sample(String name) =>
    jsonDecode(File('test/samples/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('en_GB');
  });

  group('codes (V-CODE-1)', () {
    test('normalise like the API: spaces, hyphens, lower case', () {
      expect(normaliseCode('k7pq2n'), 'K7PQ2N');
      expect(normaliseCode(' K7P-Q2N '), 'K7PQ2N');
      expect(normaliseCode('K7 PQ 2N'), 'K7PQ2N');
    });
    test('reject the wrong length and ambiguous characters', () {
      expect(normaliseCode('K7PQ2'), isNull);
      expect(normaliseCode('K7PQ2NN'), isNull);
      expect(normaliseCode('K0PQ2N'), isNull); // zero
      expect(normaliseCode('KOPQ2N'), isNull); // O
      expect(normaliseCode('K1PQ2N'), isNull);
      expect(normaliseCode('KIPQ2N'), isNull);
      expect(normaliseCode('KLPQ2N'), isNull);
    });
    test('typing keeps only code characters, upper-cased, at most six', () {
      expect(codeInput('k7-pq 2n'), 'K7PQ2N');
      expect(codeInput('k7pq2n99'), 'K7PQ2N');
      expect(codeInput('o0i1l'), '');
    });
  });

  group('formatting', () {
    final at = DateTime.parse('2026-12-14T14:30:00Z');
    test('times in the activity zone, zone named', () {
      expect(formatWhen(at, 'Africa/Nairobi'), 'Mon 14 Dec, 17:30');
      expect(formatWhen(at, 'Europe/London'), 'Mon 14 Dec, 14:30');
      expect(zoneLabel('America/New_York'), 'New York time');
    });
    test('money in minor units', () {
      expect(formatMoney(350000, 'KES'), 'KES 3,500');
      expect(formatMoney(350050, 'KES'), 'KES 3,500.50');
      expect(formatMoney(0, 'KES'), 'Free');
    });
    test('initials and first names', () {
      expect(initials('Tunde A.'), 'TA');
      expect(initials('Zainab Okafor'), 'ZO');
      expect(initials(''), '?');
      expect(firstName('Tunde Adeyemi'), 'Tunde');
    });
    test('contacts are masked, never kept whole (SEC-002)', () {
      expect(maskContact('+254 712 345 678'), '+254 712 •••');
      expect(maskContact('zainab@gmail.com'), 'z••••@gmail.com');
      expect(maskContact('123'), '•••');
      expect(maskContact('+254712345678'), isNot(contains('345')));
    });
    test('last updated', () {
      final t = DateTime.utc(2026, 11, 4, 12);
      expect(updatedAgo(t, t.add(const Duration(seconds: 20))), 'Last updated just now');
      expect(updatedAgo(t, t.add(const Duration(minutes: 10))), 'Last updated 10 min ago');
      expect(updatedAgo(t, t.add(const Duration(minutes: 125))), 'Last updated 2 hours ago');
    });
    test('vouch message (copy deck)', () {
      expect(
        vouchMessage('Wanjiru Njoroge', 'Sunset Kayaking', at, 'Africa/Nairobi', 'https://x/i/H4XM9R'),
        'Wanjiru, I’m going to Sunset Kayaking on Mon 14 Dec and want you there. Claim your spot: https://x/i/H4XM9R',
      );
    });
  });

  group('screen selection (V-INV-1, S6 §4.3)', () {
    test('every row, in order', () {
      expect(selectScreen(inviteView()), isA<OpenScreen>().having((s) => s.block, 'block', OpenBlock.none));
      expect(
        selectScreen(inviteView(status: 'claimed', claimedByViewer: true)),
        isA<ClaimedScreen>().having((s) => s.own, 'own', true),
      );
      expect(selectScreen(inviteView(status: 'claimed')), isA<ClaimedScreen>().having((s) => s.own, 'own', false));
      expect(selectScreen(inviteView(status: 'expired')), isA<ExpiredScreen>());
      expect(selectScreen(inviteView(activity: activityJson(status: 'started'))), isA<ExpiredScreen>());
      expect(selectScreen(inviteView(rail: 'public', status: 'paused', pausedReason: 'auto')), isA<PausedScreen>());
      expect(
        selectScreen(inviteView(activity: activityJson(viewer: {'isHost': true, 'booking': null}))),
        isA<OpenScreen>().having((s) => s.block, 'block', OpenBlock.host),
      );
      final going = {
        'isHost': false,
        'booking': {'id': planId, 'planId': planId, 'status': 'confirmed'},
      };
      expect(
        selectScreen(inviteView(activity: activityJson(spotsLeft: 0, viewer: going))),
        isA<OpenScreen>().having((s) => s.block, 'block', OpenBlock.alreadyGoing),
      );
      expect(selectScreen(inviteView(activity: activityJson(spotsLeft: 0))), isA<SoldOutScreen>());
      expect(
        selectScreen(inviteView(activity: activityJson(bookingsPaused: true))),
        isA<OpenScreen>().having((s) => s.block, 'block', OpenBlock.bookingsPaused),
      );
    });
    test('sold out follows the live count, not an invite state', () {
      final v = inviteView();
      expect(selectScreen(v, spotsLeft: 0), isA<SoldOutScreen>());
      expect(selectScreen(v, spotsLeft: 1), isA<OpenScreen>());
    });
  });

  group('claim rejections (V-ERR-1, S6 FR-009)', () {
    test('each code maps to its outcome', () {
      expect(claimOutcome('invalid_contact'), isA<ClaimFieldError>().having((o) => o.field, 'field', 'contact'));
      expect(claimOutcome('validation_failed'), isA<ClaimFieldError>().having((o) => o.field, 'field', 'name'));
      expect(claimOutcome('sold_out'), isA<ClaimBanner>().having((o) => o.soldOut, 'soldOut', true));
      for (final c in ['rate_limited', 'bookings_paused', 'booking_removed']) {
        expect(claimOutcome(c), isA<ClaimBanner>().having((o) => o.retry, 'retry', false), reason: c);
      }
      expect(claimOutcome('already_booked'), isA<ClaimDone>());
      for (final c in [
        'invite_expired',
        'invite_paused',
        'already_claimed',
        'activity_started',
        'forbidden',
        'invalid_code',
        'not_found',
      ]) {
        expect(claimOutcome(c), isA<ClaimBack>(), reason: c);
      }
    });
    test('network failures and server errors offer a retry', () {
      expect(claimOutcome(null), isA<ClaimBanner>().having((o) => o.retry, 'retry', true));
      expect(claimOutcome('internal'), isA<ClaimBanner>().having((o) => o.retry, 'retry', true));
    });
  });

  group('deep links (V-DL-1, SEC-005)', () {
    const base = 'https://depimls1pcvv4.cloudfront.net';
    test('invite links open the invite, normalised', () {
      expect(routeForLink(Uri.parse('$base/i/K7PQ2N'), apiBase: base), '/i/K7PQ2N');
      expect(routeForLink(Uri.parse('$base/i/k7pq2n'), apiBase: base), '/i/K7PQ2N');
      expect(routeForLink(Uri.parse('$base/i/K7PQ2N/claim'), apiBase: base), '/i/K7PQ2N');
    });
    test('a bad code goes to code entry; other paths to "newer version"; other hosts are ignored', () {
      expect(routeForLink(Uri.parse('$base/i/K0PQ2N'), apiBase: base), '/?error=invalid');
      expect(routeForLink(Uri.parse('$base/activities/x'), apiBase: base), startsWith('/update?url='));
      expect(routeForLink(Uri.parse('https://evil.example/i/K7PQ2N'), apiBase: base), isNull);
    });
  });

  group('generated models parse real responses (V-API-1)', () {
    test('invite, activity, plan, my plans, next steps, profiles', () {
      expect(InviteView.fromJson(sample('invite_public')).rail, InviteViewRailEnum.public);
      expect(InviteView.fromJson(sample('invite_vouch_member')).activity.viewer, isNotNull);
      expect(PublicActivity.fromJson(sample('activity')).location.venueName, isNotEmpty);
      final plan = PlanView.fromJson(sample('plan'));
      expect(plan.members.any((m) => m.invitedBy == null), isTrue, reason: 'direct members have no inviter');
      expect(MyPlans.fromJson(sample('my_plans')).upcoming, isNotEmpty);
      expect(NextSteps.fromJson(sample('next_steps')).hostOtherDates, isNotEmpty);
      expect(Profile.fromJson(sample('profile')).person.shortName, isNotEmpty);
      expect(Profile.fromJson(sample('profile_host')).hosting, isNotEmpty);
    });
  });
}
