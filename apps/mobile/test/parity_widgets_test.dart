// S7b widget checks: V-C1-1, V-B1-1, V-BOOK-1 (widget part), V-H3-1, V-ATT-2, V-FORM-2, V-LOC-1 and
// V-NAV-1, each at 360 px and at 390 px with text at 200% (V-WID-2). A layout overflow throws in
// tests, so each pump also checks there is none.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velio/activity/activity.dart';
import 'package:velio/activity_form/activity_form.dart';
import 'package:velio/app/router.dart';
import 'package:velio/attendance/attendance.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/host_form.dart';
import 'package:velio/domain/role.dart';
import 'package:velio/explore/explore.dart';
import 'package:velio/host_list/host_list.dart';
import 'package:velio/location_picker/location_picker.dart';
import 'package:velio/repositories/preferences_repository.dart';
import 'package:velio/shell/shell.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';
import 'harness.dart';

PublicActivity _activity({
  int spotsLeft = 6,
  String status = 'open',
  bool paused = false,
  Map<String, dynamic>? viewer,
  int members = 3,
}) => PublicActivity.fromJson({
  ...activityJson(spotsLeft: spotsLeft, status: status, bookingsPaused: paused, viewer: viewer),
  'members': {...(activityJson()['members'] as Map<String, dynamic>), 'count': members},
});

const _host = {'isHost': true, 'booking': null};

void main() {
  setUpHarness();

  group('navigation (V-NAV-1, V-NAV-2)', () {
    screenTest('booker tabs, then the toggle to Host and back', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const SizedBox(), size: size, scale: scale, app: createRouter());
      // Code entry is still the launch screen (S7 FR-004), inside the booker's bottom bar.
      expect(find.text('Got an invite code?'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await t.tap(find.text('Explore'));
      await t.pumpAndSettle();
      expect(find.text('1 upcoming activity with spots'), findsOneWidget);
      await t.tap(find.text('Host').first);
      await t.pumpAndSettle();
      expect(find.text('My activities'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(await PreferencesRepository(prefs).loadRole(), Role.host);
      await t.tap(find.text('Booker').first);
      await t.pumpAndSettle();
      expect(find.text('Got an invite code?'), findsOneWidget);
      expect(await PreferencesRepository(prefs).loadRole(), Role.booker);
    });
    screenTest('a next-step card opens the activity in the app', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.bookError = const ApiException(status: 409, code: 'sold_out');
      await pumpScreen(
        t,
        const SizedBox(),
        size: size,
        scale: scale,
        app: createRouter(initialLocation: '/activities/$activityId'),
      );
      await tapText(t, 'Book a spot');
      // The last match is the "Amara’s other dates" card, not the page title.
      await t.ensureVisible(find.text('Sunset Kayaking').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Sunset Kayaking').last);
      await t.pumpAndSettle();
      expect(find.byType(ActivityPage, skipOffstage: false), findsNWidgets(2));
    });
  });

  group('C1 community (V-C1-1)', () {
    screenTest('Explore: the first community with live cards', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const ExplorePage(), size: size, scale: scale);
      expect(find.text('Explore Kenya'), findsOneWidget);
      expect(find.text('1 upcoming activity with spots'), findsOneWidget);
      expect(find.text('Sunset Kayaking'), findsNWidgets(2));
      expect(find.byType(RoleToggle), findsOneWidget);
      // No native maps in tests: no List / Map toggle.
      expect(find.text('Map'), findsNothing);
    });
    screenTest('empty community', (t, {size = const Size(360, 800), scale = 1}) async {
      api.communityResult = CommunityPage.fromJson(communityPageJson(empty: true));
      await pumpScreen(
        t,
        const ExplorePage(slug: 'explore-kenya'),
        size: size,
        scale: scale,
      );
      expect(find.text('Nothing coming up right now'), findsOneWidget);
      expect(find.text('No upcoming activities'), findsOneWidget);
    });
  });

  group('B1 activity (V-B1-1, V-BOOK-1)', () {
    screenTest('open, signed in: a failed attempt retries with the same key', (
      t, {
      size = const Size(360, 800),
      scale = 1,
    }) async {
      await signedIn();
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('14 spots in total'), findsOneWidget);
      await tapText(t, 'Book a spot');
      expect(find.text('We couldn’t confirm your spot. Nothing was booked.'), findsOneWidget);
      await tapText(t, 'Try again');
      expect(api.bookings, hasLength(2));
      expect(api.bookings.toSet(), hasLength(1));
    });
    screenTest('sold out mid-attempt', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.bookError = const ApiException(status: 409, code: 'sold_out');
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      await tapText(t, 'Book a spot');
      expect(find.text('Someone just took the last spot.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Amara’s other dates'), findsOneWidget);
    });
    screenTest('the host sees attendance, not Book', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(viewer: _host);
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('You’re the host of this activity.'), findsOneWidget);
      expect(find.text('Open live attendance'), findsOneWidget);
      expect(find.text('Book a spot'), findsNothing);
    });
    screenTest('already going', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(
        viewer: {
          'isHost': false,
          'booking': {'id': planId, 'planId': planId, 'status': 'confirmed'},
        },
      );
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('You’re already going'), findsOneWidget);
    });
    screenTest('started, paused, sold out', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(status: 'started');
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('This activity has started.'), findsOneWidget);
      expect(find.text('Bookings closed'), findsOneWidget);

      api.activityResult = _activity(paused: true);
      await pumpScreen(
        t,
        const ActivityPage(id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e11'),
        size: size,
        scale: scale,
      );
      expect(find.text('Bookings paused'), findsOneWidget);

      api.activityResult = _activity(spotsLeft: 0, status: 'sold_out');
      await pumpScreen(
        t,
        const ActivityPage(id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e12'),
        size: size,
        scale: scale,
      );
      expect(find.text('Sold out'), findsWidgets);
    });
    screenTest('offline: Reconnect to book, nothing sent', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      online = false;
      await pumpScreen(
        t,
        const ActivityPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('Reconnect to book'), findsOneWidget);
      await t.tap(find.text('Reconnect to book'), warnIfMissed: false);
      expect(api.bookings, isEmpty);
    });
  });

  group('H3 My activities (V-H3-1)', () {
    screenTest('signed out asks to sign in', (t, {size = const Size(360, 800), scale = 1}) async {
      await pumpScreen(t, const HostListPage(), size: size, scale: scale);
      expect(find.text('Host on Velio'), findsOneWidget);
      expect(find.text('Create'), findsNothing);
    });
    screenTest('upcoming and past', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await pumpScreen(t, const HostListPage(), size: size, scale: scale);
      expect(find.text('6 spots left'), findsOneWidget);
      expect(find.text('No bookings yet'), findsOneWidget);
      await tapText(t, 'Past');
      expect(find.text('5 attended'), findsOneWidget);
    });
    screenTest('no activities yet', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.hostResult = HostActivityList.fromJson(hostListJson(empty: true));
      await pumpScreen(t, const HostListPage(), size: size, scale: scale);
      expect(find.text('No activities yet'), findsOneWidget);
      expect(find.text('Create activity'), findsOneWidget);
    });
  });

  group('H1 attendance (V-ATT-2)', () {
    screenTest('before the start: Remove asks first', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(viewer: _host);
      await pumpScreen(
        t,
        const AttendancePage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('Via Tunde'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('2 of 14'), findsOneWidget);
      expect(find.text('Edit activity'), findsOneWidget);
      // Newest first: Guest2's row leads.
      await t.ensureVisible(find.text('Remove').first);
      await t.tap(find.text('Remove').first);
      await t.pumpAndSettle();
      expect(find.text('Remove Guest2 Gathoni?'), findsOneWidget);
      await tapText(t, 'Keep');
      expect(api.removals, isEmpty);
      await t.ensureVisible(find.text('Remove').first);
      await t.tap(find.text('Remove').first);
      await t.pumpAndSettle();
      await tapText(t, 'Remove Guest2');
      expect(api.removals, ['0190a6f2-0000-7000-8000-0000000000a2']);
      expect(find.text('Guest2 removed. Their spot is open again.'), findsOneWidget);
    });
    screenTest('after the start: marks, reverted on failure', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(viewer: _host);
      api.attendanceResult = Attendance.fromJson(attendanceJson(started: true));
      await pumpScreen(
        t,
        const AttendancePage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('Who came?'), findsOneWidget);
      expect(find.text('The activity has started.'), findsOneWidget);
      expect(find.text('Edit activity'), findsNothing);
      await tapText(t, 'Attended');
      expect(api.marks, ['0190a6f2-0000-7000-8000-0000000000a1/attended']);
      expect(find.text('You can mark attendance once the activity starts.'), findsOneWidget);
    });
    screenTest('search and empty', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(viewer: _host);
      await pumpScreen(
        t,
        const AttendancePage(id: activityId),
        size: size,
        scale: scale,
      );
      await t.enterText(find.byType(TextField).first, 'zz');
      await t.pumpAndSettle();
      expect(find.text('No guest matches “zz”.'), findsOneWidget);

      api.attendanceResult = Attendance.fromJson(attendanceJson(empty: true));
      await pumpScreen(
        t,
        const AttendancePage(id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e11'),
        size: size,
        scale: scale,
      );
      expect(find.text('No bookings yet'), findsOneWidget);
    });
  });

  group('H2 create and edit (V-FORM-2, V-LOC-1)', () {
    screenTest('create: Publish on an empty form shows the summary', (
      t, {
      size = const Size(360, 800),
      scale = 1,
    }) async {
      await signedIn();
      await pumpScreen(t, const ActivityFormPage(), size: size, scale: scale);
      expect(find.text('Create an activity'), findsOneWidget);
      // No Places key and no Maps in tests: the pin is typed in.
      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text(pinPublicNote), findsOneWidget);
      expect(find.text('Africa/Nairobi'), findsOneWidget);
      await tapText(t, 'Publish');
      expect(find.text('6 things need fixing before you can publish.'), findsOneWidget);
      expect(find.text('Add a title.'), findsOneWidget);
      expect(api.created, isEmpty);
    });
    screenTest('edit after bookings: locked', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      api.activityResult = _activity(viewer: _host);
      await pumpScreen(
        t,
        const ActivityFormPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text(lockedNote), findsOneWidget);
      expect(find.text('Location is locked because people have booked.'), findsOneWidget);
      expect(find.text('3 booked, so at least 3. You can always add more.'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });
    screenTest('not the host: not found', (t, {size = const Size(360, 800), scale = 1}) async {
      await signedIn();
      await pumpScreen(
        t,
        const ActivityFormPage(id: activityId),
        size: size,
        scale: scale,
      );
      expect(find.text('We can’t find that.'), findsOneWidget);
    });
  });
}
