// V-WID-1, V-CMP-1, V-INV-1 (widget part), V-CLM-1, V-PLAN-1, V-MY-1, V-PROF-1, V-ERR-1, V-OFF-1:
// every screen's designed states at 360 px, and at 390 px with text at 200% (UI-D5, AC-005). A layout
// overflow throws in tests, so each pump also checks there is none.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velio/core/api.dart';
import 'package:velio/features/claim.dart';
import 'package:velio/features/code_entry.dart';
import 'package:velio/features/errors.dart';
import 'package:velio/features/invite.dart';
import 'package:velio/features/my_plans.dart';
import 'package:velio/features/plan.dart';
import 'package:velio/features/profile.dart';
import 'package:velio/features/signin.dart';
import 'package:velio/ui/components.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';
import 'harness.dart';

void main() {
  setUpHarness();

  group('components (V-CMP-1)', () {
    testWidgets('spots badge: five states', (t) async {
      await pumpScreen(
        t,
        const Scaffold(
          body: Column(
            children: [
              SpotsBadge(spots: 6),
              SpotsBadge(spots: 5, state: SpotsState.changed),
              SpotsBadge(spots: 2),
              SpotsBadge(spots: 1),
              SpotsBadge(spots: 0),
              SpotsBadge(spots: 4, state: SpotsState.stale),
            ],
          ),
        ),
      );
      for (final s in ['6 spots left', '5 spots left', 'Last 2 spots', 'Last spot', 'Sold out', 'Reconnecting…']) {
        expect(find.text(s), findsOneWidget);
      }
    });
    test('who is going', () {
      expect(goingLabel(const [], 0), 'Be the first to book');
      expect(goingLabel(const [StackPerson('Tunde A.')], 0), 'Tunde A. is going');
      expect(goingLabel(const [StackPerson('A'), StackPerson('B')], 0), 'A and B are going');
      expect(
        goingLabel(const [StackPerson('A'), StackPerson('B'), StackPerson('C')], 2),
        'A, B and 3 others are going',
      );
    });
  });

  group('G8 code entry (V-CODE-1)', () {
    screenTest('empty, then a typed code enables Open', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const CodeEntryScreen(), size: size, scale: scale);
      expect(find.text('Got an invite code?'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'k7-pq2n');
      await t.pump();
      expect(fieldText(t), 'K7PQ2N');
    });
    screenTest('unknown code inline, code kept', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteError = const ApiException(status: 404, code: 'invalid_code');
      await pumpScreen(t, const CodeEntryScreen(), size: size, scale: scale);
      await t.enterText(find.byType(TextField), 'K7PQ2M');
      await t.pump();
      await tapText(t, 'Open invite');
      expect(find.text(invalidCodeError), findsOneWidget);
      expect(fieldText(t), 'K7PQ2M');
    });
    screenTest('rate limited', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(
        t,
        const CodeEntryScreen(initialError: 'limited'),
        size: size,
        scale: scale,
      );
      expect(find.text(rateLimitedError), findsOneWidget);
      expect(find.text('Try again in an hour'), findsOneWidget);
    });
  });

  group('invite (V-INV-1, V-INV-2, V-OFF-1)', () {
    screenTest('G1 vouch, with the open beacon', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('Sunset Kayaking'), findsOneWidget);
      expect(find.textContaining('wants you on', findRichText: true), findsOneWidget);
      expect(find.text('Claim my spot'), findsOneWidget);
      expect(find.text('KES 3,500 · pay the host on the day'), findsOneWidget);
      expect(api.opens, ['K7PQ2N/android']);
      // Public screens show short names only (SEC-003).
      expect(find.textContaining('Adeyemi'), findsNothing);
    });
    screenTest('G2 public', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteResult = inviteView(rail: 'public');
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('Join the group going to'), findsOneWidget);
      expect(find.text('Explore Kenya'), findsOneWidget);
    });
    screenTest('G5 sold out with next steps', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteResult = inviteView(activity: activityJson(spotsLeft: 0));
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('This one filled up before you got here.'), findsOneWidget);
      expect(find.text('Tell Tunde'), findsOneWidget);
      expect(find.text('Amara’s other dates'), findsOneWidget);
    });
    screenTest('G6 expired', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteResult = inviteView(status: 'expired');
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('This invite expired when the activity started.'), findsOneWidget);
    });
    screenTest('G7 claimed by someone else', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteResult = inviteView(status: 'claimed');
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('This invite has already been claimed.'), findsOneWidget);
      expect(find.text('Continue with your phone or email'), findsOneWidget);
    });
    screenTest('paused link', (t, {size = const Size(360, 800), scale = 1}) async {
      api.inviteResult = inviteView(rail: 'public', status: 'paused', pausedReason: 'auto');
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('This link is paused.'), findsOneWidget);
    });
    screenTest('offline: the saved invite, Claim waits, no map (FR-015, FR-016)', (
      t, {
      size = const Size(360, 800),
      scale = 1,
    }) async {
      await cache.saveInvite(inviteView(), DateTime.utc(2026, 11, 4, 12));
      api.inviteError = const ApiException(message: 'network');
      await pumpScreen(
        t,
        const InviteScreenPage(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('You’re offline · Last updated 10 min ago'), findsOneWidget);
      expect(find.text('Reconnect to claim'), findsOneWidget);
      expect(find.text('Claim my spot'), findsNothing);
      expect(find.text('Map unavailable offline'), findsOneWidget);
      expect(find.text('Lake Naivasha Boat Club'), findsOneWidget);
      expect(api.opens, isEmpty, reason: 'no beacon for a cached view');
    });
  });

  group('claim (V-CLM-1)', () {
    screenTest('new guest: two fields and the disclosure', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(
        t,
        const ClaimScreen(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Phone or email'), findsOneWidget);
      expect(find.textContaining('Amara (the host) will see your name and that Tunde invited you'), findsOneWidget);
    });
    screenTest('returning guest: Claiming as, masked contact', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await pumpScreen(
        t,
        const ClaimScreen(code: 'K7PQ2N'),
        size: size,
        scale: scale,
      );
      expect(find.text('Claiming as Zainab Okafor'), findsOneWidget);
      expect(find.text('+254 712 ••• · saved on this phone'), findsOneWidget);
      expect(find.text('Not you?'), findsOneWidget);
    });
    testWidgets('a failed claim offers Try again with the same key; nothing is queued', (t) async {
      await signedIn();
      await pumpScreen(t, const ClaimScreen(code: 'K7PQ2N'));
      await tapText(t, 'Confirm my spot');
      expect(find.text('We couldn’t confirm your spot. Nothing was booked.'), findsOneWidget);
      await tapText(t, 'Try again');
      expect(api.claims, hasLength(2));
      expect(api.claims[1], api.claims[0]);
    });
    testWidgets('sold out on claim: banner, no retry', (t) async {
      await signedIn();
      api.claimError = const ApiException(status: 409, code: 'sold_out');
      await pumpScreen(t, const ClaimScreen(code: 'K7PQ2N'));
      await tapText(t, 'Confirm my spot');
      expect(find.text('Someone just took the last spot.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
    testWidgets('offline: Reconnect to claim, disabled', (t) async {
      online = false;
      await pumpScreen(t, const ClaimScreen(code: 'K7PQ2N'));
      expect(find.text('Reconnect to claim'), findsOneWidget);
      await t.tap(find.text('Reconnect to claim'));
      await t.pump();
      expect(api.claims, isEmpty);
    });
  });

  group('G4 and Plan (V-CLM-2, V-PLAN-1)', () {
    screenTest('You’re in', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await pumpScreen(
        t,
        const YoureInScreen(planId: planId),
        size: size,
        scale: scale,
      );
      expect(find.text('You’re in, Zainab.'), findsOneWidget);
      expect(find.text('VLO-48213'), findsOneWidget);
      expect(find.text('See the plan'), findsOneWidget);
      expect(find.text('Invite a friend'), findsOneWidget);
      expect(find.text('Tunde and you'), findsOneWidget);
    });
    screenTest('Plan: members, sources, invite status', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await pumpScreen(
        t,
        const PlanScreen(planId: planId),
        size: size,
        scale: scale,
      );
      expect(find.text('Going · 2'), findsOneWidget);
      expect(find.text('Zainab Okafor (you)'), findsOneWidget);
      expect(find.text('Via Tunde'), findsOneWidget);
      expect(find.text('Direct'), findsOneWidget);
      expect(find.text('Invite for Wanjiru'), findsOneWidget);
      expect(find.text('Opened'), findsOneWidget);
    });
    screenTest('Plan: removed by the host', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.planResult = PlanView.fromJson(planJson(bookingStatus: 'removed'));
      await pumpScreen(
        t,
        const PlanScreen(planId: planId),
        size: size,
        scale: scale,
      );
      expect(find.text('The host removed this booking.'), findsOneWidget);
      expect(find.text('Invite a friend'), findsNothing);
    });
    testWidgets('invite sheet: choose, then vouch form', (t) async {
      await signedIn();
      await pumpScreen(t, const PlanScreen(planId: planId));
      await tapText(t, 'Invite a friend');
      expect(find.text('Vouch for a friend'), findsOneWidget);
      await tapText(t, 'Vouch for a friend');
      await tapText(t, 'Create and share');
      expect(find.text('Add their name, so the invite is addressed to them.'), findsOneWidget);
    });
  });

  group('My plans (V-MY-1, V-OFF-1)', () {
    screenTest('upcoming', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.plansResult = MyPlans(
        upcoming: [
          myPlan(),
          myPlan(status: 'removed'),
        ],
        past: const [],
      );
      await pumpScreen(t, const MyPlansScreen(), size: size, scale: scale);
      expect(find.text('VLO-48213'), findsOneWidget);
      expect(find.text('Removed by host'), findsOneWidget);
    });
    screenTest('empty', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.plansResult = MyPlans(upcoming: const [], past: const []);
      await pumpScreen(t, const MyPlansScreen(), size: size, scale: scale);
      expect(find.text('No plans yet'), findsOneWidget);
    });
    screenTest('signed out on a new phone', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const MyPlansScreen(), size: size, scale: scale);
      expect(find.text('Continue with your phone or email'), findsOneWidget);
    });
    screenTest('offline from the saved list', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await cache.saveMyPlans(MyPlans(upcoming: [myPlan()], past: const []), DateTime.utc(2026, 11, 4, 11, 45));
      api.plansError = const ApiException(message: 'network');
      await pumpScreen(t, const MyPlansScreen(), size: size, scale: scale);
      expect(find.text('You’re offline · Last updated 25 min ago'), findsOneWidget);
      expect(find.text('Showing your saved plans.'), findsOneWidget);
      expect(find.text('Sunset Kayaking'), findsOneWidget);
    });
  });

  group('profile, sign in, errors (V-PROF-1, V-ERR-1)', () {
    screenTest('P1 host and guest', (t, {size = const Size(360, 800), scale = 1}) async {
      api.profileResult = Profile.fromJson({
        'person': person('u1', 'Tunde A.'),
        'memberSince': '2023-06',
        'hosting': const [],
      });
      await pumpScreen(
        t,
        const ProfileScreen(userId: 'u1'),
        size: size,
        scale: scale,
      );
      expect(find.text('On Velio since June 2023'), findsOneWidget);
      expect(find.text('Tunde isn’t hosting anything right now.'), findsOneWidget);
    });
    screenTest('X1 sign in, empty submit', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const SignInScreen(), size: size, scale: scale);
      await tapText(t, 'Continue');
      expect(find.text('Enter your name.'), findsOneWidget);
    });
    for (final kind in ErrorKind.values) {
      screenTest('X4 ${kind.name}', (t, {size = const Size(360, 800), scale = 1}) async {
        await pumpScreen(
          t,
          ErrorScreen(kind: kind, onRetry: () {}),
          size: size,
          scale: scale,
        );
        expect(find.text('My plans'), findsOneWidget);
      });
    }
  });
}
