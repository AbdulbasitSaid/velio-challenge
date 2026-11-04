// The widget tests' harness: a fake API, a socket that never opens, and pumpScreen at a phone size
// and text scale. Shared by widgets_test.dart (S7) and parity_widgets_test.dart (S7b).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:velio/app/theme.dart';
import 'package:velio/core/api.dart';
import 'package:velio/core/cache.dart';
import 'package:velio/core/identity.dart';
import 'package:velio/core/online.dart';
import 'package:velio/core/providers.dart';
import 'package:velio/core/realtime.dart';
import 'package:velio/features/claim.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';

class FakeApi extends Api {
  FakeApi(Identity identity) : super(Dio(), identity);
  InviteView? inviteResult;
  ApiException? inviteError;
  PlanView? planResult;
  MyPlans? plansResult;
  ApiException? plansError;
  Profile? profileResult;
  final opens = <String>[];
  final claims = <String>[];
  ApiException? claimError;

  @override
  Future<InviteView> invite(String code) async =>
      inviteError != null ? throw inviteError! : inviteResult ?? inviteView();
  @override
  Future<void> open(String code, String platform) async => opens.add('$code/$platform');
  @override
  Future<NextSteps> nextSteps(String activityId) async => NextSteps(
    hostOtherDates: [
      ActivityCard.fromJson({...activityJson(spotsLeft: 4), 'location': cardLoc}),
    ],
    moreInCommunity: const [],
  );
  PublicActivity? activityResult;
  ApiException? activityError;
  @override
  Future<PublicActivity> activity(String id) async =>
      activityError != null ? throw activityError! : activityResult ?? PublicActivity.fromJson(activityJson());

  // ---- S7b ----
  CommunityPage? communityResult;
  @override
  Future<CommunityList> communities() async => CommunityList.fromJson({
    'communities': [communityJson()],
  });
  @override
  Future<CommunityPage> community(String slug) async => communityResult ?? CommunityPage.fromJson(communityPageJson());

  final bookings = <String>[];
  ApiException? bookError;
  @override
  Future<BookingResponse> book(String activityId, {required String idempotencyKey}) async {
    bookings.add(idempotencyKey);
    throw bookError ?? const ApiException(message: 'network');
  }

  HostActivityList? hostResult;
  @override
  Future<HostActivityList> hostActivities() async => hostResult ?? HostActivityList.fromJson(hostListJson());

  Attendance? attendanceResult;
  final marks = <String>[];
  final removals = <String>[];
  @override
  Future<Attendance> attendance(String activityId) async => attendanceResult ?? Attendance.fromJson(attendanceJson());
  @override
  Future<Attendee> mark(String bookingId, AttendanceMark mark) async {
    marks.add('$bookingId/${mark.value}');
    throw const ApiException(status: 409, code: 'activity_not_started');
  }

  @override
  Future<void> removeBooking(String bookingId) async => removals.add(bookingId);

  final created = <Map<String, Object?>>[];
  @override
  Future<String> createActivity(Map<String, Object?> body) async {
    created.add(body);
    return activityId;
  }

  @override
  Future<PlanView> plan(String id) async => planResult ?? PlanView.fromJson(planJson());
  @override
  Future<MyPlans> myPlans() async => plansError != null ? throw plansError! : plansResult!;
  @override
  Future<Profile> profile(String userId) async => profileResult!;
  @override
  Future<ClaimResponse> claim(
    String code, {
    required String idempotencyKey,
    required String platform,
    String? displayName,
    String? contact,
  }) async {
    claims.add(idempotencyKey);
    throw claimError ?? const ApiException(message: 'network');
  }
}

const cardLoc = {'venueName': 'Lake Naivasha Boat Club', 'lat': -0.7667, 'lng': 36.4333};

MyPlan myPlan({String status = 'confirmed'}) => MyPlan.fromJson({
  'planId': planId,
  'activity': {...activityJson(), 'location': cardLoc},
  'booking': {'id': planId, 'ref': 'VLO-48213', 'status': status},
  'members': {
    'count': 3,
    'preview': [member('0190a6f2-0000-7000-8000-000000000002', 'Tunde A.', 'Tunde Adeyemi')],
  },
});

/// The socket never opens: screens show their reconnecting state, as on a slow network.
RealtimeClient quietRealtime() =>
    RealtimeClient(url: Uri.parse('wss://x.test/api/ws'), platform: 'android', createSocket: (_) => NeverSocket());

class NeverSocket implements RealtimeSocket {
  @override
  Stream<dynamic> get messages => const Stream.empty();
  @override
  Future<void> get ready => Completer<void>().future;
  @override
  void send(String data) {}
  @override
  void close() {}
}

late Identity identity;
late FakeApi api;
late OfflineCache cache;
late SharedPreferencesAsync prefs;
bool online = true;

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 800),
  double scale = 1,

  /// The app's own router instead of [screen] alone (S7b V-NAV-1).
  GoRouter? app,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router =
      app ??
      GoRouter(
        initialLocation: '/test',
        routes: [GoRoute(path: '/test', builder: (_, _) => screen)],
        errorBuilder: (_, _) => const SizedBox.shrink(),
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        identityProvider.overrideWithValue(identity),
        apiProvider.overrideWithValue(api),
        cacheProvider.overrideWithValue(cache),
        realtimeProvider.overrideWithValue(quietRealtime()),
        platformProvider.overrideWithValue('android'),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 4, 12, 10)),
        onlineProvider.overrideWith((ref) => Stream.value(online)),
        attemptKeysProvider.overrideWithValue(AttemptKeys(prefs)),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: MaterialApp.router(theme: velioTheme(), routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the control into view, as a person would, then taps it.
Future<void> tapText(WidgetTester t, String text) async {
  await t.ensureVisible(find.text(text).first);
  await t.pumpAndSettle();
  await t.tap(find.text(text).first);
  await t.pumpAndSettle();
}

String fieldText(WidgetTester t) => t.widget<TextField>(find.byType(TextField)).controller!.text;

/// Each case runs at 360 px and at 390 px with 200% text.
void screenTest(String name, Future<void> Function(WidgetTester tester, {Size size, double scale}) body) {
  testWidgets('$name · 360 px', (t) => body(t, size: const Size(360, 800), scale: 1));
  testWidgets('$name · 390 px, 200% text', (t) => body(t, size: const Size(390, 844), scale: 2));
}

Future<void> signedIn() => identity.signIn(
  'tok',
  const LocalProfile(
    userId: '0190a6f2-0000-7000-8000-000000000009',
    displayName: 'Zainab Okafor',
    maskedContact: '+254 712 •••',
  ),
);

/// Both widget suites' setUpAll and setUp.
void setUpHarness() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('en_GB');
  });

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
    identity = Identity(MemorySecretStore(), prefs);
    await identity.load();
    api = FakeApi(identity);
    cache = OfflineCache(prefs);
    online = true;
  });
}
