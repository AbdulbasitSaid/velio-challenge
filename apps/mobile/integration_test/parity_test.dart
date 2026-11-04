// S7b V-MAN-1 integration run, on a simulator or device against a running API (local Compose only:
// it publishes an activity and books spots):
//   flutter test integration_test/parity_test.dart --dart-define=API_BASE_URL=http://localhost:3001
// A booker books from Explore; then, as host, they publish an activity with a photo, watch a second
// person's booking arrive live in attendance, and remove it. The gallery is replaced by a generated
// image so no system UI is involved.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:velio/core/api.dart';
import 'package:velio/core/providers.dart';
import 'package:velio/features/attendance.dart';
import 'package:velio/main.dart' as app;
import 'package:velio/ui/components.dart';

import 'smoke_test.dart' show tapText, waitFor;

final stamp = DateTime.now().millisecondsSinceEpoch % 100000;

Finder field(String label) =>
    find.descendant(of: find.widgetWithText(VTextField, label), matching: find.byType(TextField));

Future<void> enter(WidgetTester t, Finder f, String text) async {
  await t.ensureVisible(f);
  await t.pump(const Duration(milliseconds: 300));
  await t.enterText(f, text);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('book as a booker, then host: publish, live attendance, remove', (t) async {
    final photo = img.encodePng(img.Image(width: 1600, height: 1000)..clear(img.ColorRgb8(30, 90, 60)));
    await app.run(overrides: [photoPickerProvider.overrideWithValue(() async => photo)]);
    await waitFor(t, find.text('Got an invite code?'));

    // Booker: Explore → an activity with spots → sign in → Book → You're in.
    await tapText(t, 'Explore');
    await waitFor(t, find.textContaining('upcoming activit'));
    final card = find.textContaining('spots left').first;
    await waitFor(t, card);
    await t.ensureVisible(card);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(card);
    await waitFor(t, find.text('Book a spot'));
    await tapText(t, 'Book a spot');
    await waitFor(t, find.text('Continue'));
    await enter(t, find.byType(TextField).at(0), 'E2E Host $stamp');
    await enter(t, find.byType(TextField).at(1), 'e2e.host.$stamp@example.com');
    await tapText(t, 'Continue');
    await waitFor(t, find.text('Book a spot'));
    await tapText(t, 'Book a spot');
    await waitFor(t, find.textContaining('You’re in, '));
    expect(find.byWidgetPredicate((w) => w is SelectableText && (w.data ?? '').startsWith('VLO-')), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Close'));
    await waitFor(t, find.text('Got an invite code?'));

    // Host: toggle → My activities → Create.
    await tapText(t, 'Host');
    await waitFor(t, find.text('My activities'));
    await tapText(t, 'Create');
    await waitFor(t, find.text('Choose a photo'));
    await tapText(t, 'Choose a photo');
    await waitFor(t, find.text('Change photo'), timeout: const Duration(seconds: 40));
    await enter(t, field('Title'), 'E2E Kayak $stamp');
    await enter(t, field('Description'), 'Created by the S7b integration run.');

    await tapText(t, 'Pick a date');
    await waitFor(t, find.byTooltip('Next month'));
    await t.tap(find.byTooltip('Next month'));
    await t.pumpAndSettle();
    await t.tap(find.text('15').last);
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    await tapText(t, 'Pick a time');
    await waitFor(t, find.text('OK'));
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    // No Places key and no Maps in this build: the place is typed in (FR-010).
    await enter(t, field('Venue name'), 'Lake Naivasha Boat Club');
    await enter(t, field('Address'), 'Moi South Lake Rd, Naivasha, Kenya');
    await enter(t, field('Latitude'), '-0.7667');
    await enter(t, field('Longitude'), '36.4333');
    await enter(t, field('Price per person (KES)'), '2,500');
    await tapText(t, 'Publish');
    await waitFor(t, find.textContaining('Published. E2E Kayak $stamp is live in'));

    final router = GoRouter.of(t.element(find.byType(Scaffold).last));
    final id = router.state.uri.pathSegments[1];

    // Live attendance: a second person books through the API and the row arrives by itself (FR-011).
    await tapText(t, 'Open live attendance');
    await waitFor(t, find.text('No bookings yet'));
    await waitFor(t, find.text('Live'));
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'x-client': 'mobile'}));
    final session = await dio.post<Map<String, dynamic>>(
      '/api/sessions',
      data: {'displayName': 'E2E Guest $stamp', 'contact': 'e2e.guest.$stamp@example.com'},
    );
    await dio.post<void>(
      '/api/activities/$id/bookings',
      options: Options(
        headers: {'authorization': 'Bearer ${session.data!['token']}', 'idempotency-key': const Uuid().v4()},
      ),
    );
    await waitFor(t, find.text('E2E Guest $stamp'));
    expect(find.textContaining('Booked just now'), findsOneWidget);
    expect(find.text('1 of 10'), findsOneWidget);

    // Remove, confirmed first (FR-012).
    await tapText(t, 'Remove');
    await waitFor(t, find.text('Remove E2E Guest $stamp?'));
    await tapText(t, 'Remove E2E');
    await waitFor(t, find.text('E2E removed. Their spot is open again.'));
    expect(find.byType(AttendanceScreen), findsOneWidget);
  });
}
