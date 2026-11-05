// ActivityBloc (V-BLOC-1): load and its failures, live spots with the version gate, the members
// refetch, next steps, sign-in reloads, and Book's outcomes with the attempt key (REQUIREMENTS §7).
import 'dart:async';
import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/activity/activity.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/live.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/repositories/activity_repository.dart';
import 'package:velio/repositories/live_repository.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio_api/velio_api.dart' hide ActivityState;

import '../fixtures.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockLiveRepository extends Mock implements LiveRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

/// Always the same delay, so the members refetch is predictable.
class FixedRandom implements Random {
  FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

final activity = PublicActivity.fromJson(activityJson());
final bookingResponse = BookingResponse.fromJson({
  'booking': {
    'id': planId,
    'ref': 'VLO-48213',
    'activityId': activityId,
    'planId': planId,
    'source': 'direct',
    'status': 'confirmed',
    'createdAt': '2026-11-04T12:00:00.000Z',
  },
  'activity': {'id': activityId, 'spotsLeft': 5, 'version': 4},
});

void main() {
  late MockActivityRepository activities;
  late MockLiveRepository live;
  late MockSessionRepository session;
  late StreamController<LiveUpdate> updates;
  late StreamController<LocalProfile?> sessions;

  setUp(() {
    activities = MockActivityRepository();
    live = MockLiveRepository();
    session = MockSessionRepository();
    updates = StreamController<LiveUpdate>();
    sessions = StreamController<LocalProfile?>.broadcast();
    when(() => activities.activity(activityId)).thenAnswer((_) async => activity);
    when(() => activities.nextSteps(activityId))
        .thenAnswer((_) async => NextSteps(hostOtherDates: const [], moreInCommunity: const []));
    when(() => activities.clearAttempt(activityId)).thenAnswer((_) async {});
    when(() => live.status).thenReturn(RealtimeStatus.live);
    when(() => live.watch(any())).thenAnswer((_) => updates.stream);
    when(() => session.changes).thenAnswer((_) => sessions.stream);
    when(() => session.signedIn).thenReturn(true);
  });

  ActivityBloc build() => ActivityBloc(
    activityRepository: activities,
    liveRepository: live,
    sessionRepository: session,
    id: activityId,
    random: FixedRandom(100),
  );

  const count = LiveCount(spotsLeft: 6, version: 3);
  final loaded = ActivityState(
    status: ActivityStatus.success,
    activity: activity,
    members: activity.members,
    live: count,
  );

  group('load', () {
    blocTest<ActivityBloc, ActivityState>(
      'loads the activity, then follows its spots',
      build: build,
      act: (b) => b.add(const ActivityRequested()),
      expect: () => [loaded, loaded.copyWith(realtime: RealtimeStatus.live)],
      verify: (_) => verify(() => live.watch(['activity:$activityId'])).called(1),
    );

    for (final (status, error) in [(404, LoadError.notFound), (400, LoadError.notFound), (500, LoadError.server)]) {
      blocTest<ActivityBloc, ActivityState>(
        '$status is ${error.name}',
        setUp: () => when(() => activities.activity(activityId)).thenThrow(ApiException(status: status, code: 'x')),
        build: build,
        act: (b) => b.add(const ActivityRequested()),
        expect: () => [ActivityState(status: ActivityStatus.failure, error: error)],
      );
    }

    blocTest<ActivityBloc, ActivityState>(
      'offline, then Try again shows the skeleton and loads',
      setUp: () {
        var calls = 0;
        when(() => activities.activity(activityId)).thenAnswer((_) async {
          if (calls++ == 0) throw const ApiException(message: 'network');
          return activity;
        });
      },
      build: build,
      act: (b) async {
        b.add(const ActivityRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ActivityRequested());
      },
      expect: () => [
        const ActivityState(status: ActivityStatus.failure, error: LoadError.offline),
        const ActivityState(),
        loaded,
        loaded.copyWith(realtime: RealtimeStatus.live),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'a sign-in or sign-out reloads',
      build: build,
      act: (b) async {
        b.add(const ActivityRequested());
        await Future<void>.delayed(Duration.zero);
        sessions.add(null);
      },
      verify: (_) => verify(() => activities.activity(activityId)).called(2),
    );
  });

  group('live', () {
    blocTest<ActivityBloc, ActivityState>(
      'only a newer version is shown, and each shown event is acknowledged',
      build: build,
      seed: () => loaded,
      act: (b) => b
        ..add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 9, 2)))
        ..add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 5, 4)))
        ..add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 5, 5))),
      expect: () => [
        loaded.copyWith(live: const LiveCount(spotsLeft: 5, version: 4, changed: true)),
        loaded.copyWith(live: const LiveCount(spotsLeft: 5, version: 5)),
      ],
      verify: (_) {
        verifyNever(() => live.rendered(activityId, 2));
        verify(() => live.rendered(activityId, 4)).called(1);
        verify(() => live.rendered(activityId, 5)).called(1);
      },
    );

    blocTest<ActivityBloc, ActivityState>(
      'who is going is refetched once after quick changes',
      build: build,
      seed: () => loaded,
      act: (b) async {
        b.add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 5, 4)));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        b.add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 4, 5)));
      },
      wait: const Duration(milliseconds: 300),
      verify: (_) => verify(() => activities.activity(activityId)).called(1),
    );

    blocTest<ActivityBloc, ActivityState>(
      'reconnecting and a refresh request',
      setUp: () => when(() => live.status).thenReturn(RealtimeStatus.reconnecting),
      build: build,
      seed: () => loaded,
      act: (b) => b
        ..add(const ActivityLiveUpdated(LiveStatusChanged(RealtimeStatus.reconnecting)))
        ..add(const ActivityLiveUpdated(LiveRefreshRequested())),
      expect: () => [loaded.copyWith(realtime: RealtimeStatus.reconnecting)],
      verify: (_) => verify(() => activities.activity(activityId)).called(1),
    );

    blocTest<ActivityBloc, ActivityState>(
      'landing on sold out asks for next steps once',
      build: build,
      seed: () => loaded,
      act: (b) => b
        ..add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 0, 4)))
        ..add(const ActivityLiveUpdated(LiveSpotsChanged(activityId, 0, 5))),
      verify: (b) {
        verify(() => activities.nextSteps(activityId)).called(1);
        expect(b.state.next, isNotNull);
      },
    );
  });

  group('book', () {
    blocTest<ActivityBloc, ActivityState>(
      'signed out: sign in first, nothing sent',
      setUp: () => when(() => session.signedIn).thenReturn(false),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      expect: () => [loaded.withEffect(ActivityEffect.signIn)],
      verify: (_) => verifyNever(() => activities.book(any())),
    );

    blocTest<ActivityBloc, ActivityState>(
      'success clears the key and reports the Plan',
      setUp: () => when(() => activities.book(activityId)).thenAnswer((_) async => bookingResponse),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      expect: () => [
        loaded.copyWith(attempt: BookingAttempt.booking),
        loaded.copyWith(bookedPlanId: planId).withEffect(ActivityEffect.booked),
      ],
      verify: (_) => verify(() => activities.clearAttempt(activityId)).called(1),
    );

    blocTest<ActivityBloc, ActivityState>(
      'a second tap while booking is ignored',
      setUp: () => when(() => activities.book(activityId)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return bookingResponse;
      }),
      build: build,
      seed: () => loaded,
      act: (b) => b
        ..add(const ActivityBookPressed())
        ..add(const ActivityBookPressed()),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => activities.book(activityId)).called(1),
    );

    blocTest<ActivityBloc, ActivityState>(
      'a network failure keeps the key for Try again',
      setUp: () => when(() => activities.book(activityId)).thenThrow(const ApiException(message: 'network')),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      expect: () => [loaded.copyWith(attempt: BookingAttempt.booking), loaded.copyWith(attempt: BookingAttempt.error)],
      verify: (_) => verifyNever(() => activities.clearAttempt(any())),
    );

    blocTest<ActivityBloc, ActivityState>(
      'sold out mid-attempt: banner, haptic, next steps, key cleared',
      setUp: () => when(() => activities.book(activityId)).thenThrow(const ApiException(status: 409, code: 'sold_out')),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      expect: () => [
        loaded.copyWith(attempt: BookingAttempt.booking),
        loaded.copyWith(attempt: BookingAttempt.soldOut).withEffect(ActivityEffect.soldOut),
        isA<ActivityState>().having((s) => s.next, 'next', isNotNull),
      ],
      verify: (_) => verify(() => activities.clearAttempt(activityId)).called(1),
    );

    for (final (code, attempt) in [
      ('activity_started', BookingAttempt.started),
      ('bookings_paused', BookingAttempt.paused),
    ]) {
      blocTest<ActivityBloc, ActivityState>(
        '$code: ${attempt.name}, key cleared',
        setUp: () => when(() => activities.book(activityId)).thenThrow(ApiException(status: 409, code: code)),
        build: build,
        seed: () => loaded,
        act: (b) => b.add(const ActivityBookPressed()),
        expect: () => [
          loaded.copyWith(attempt: BookingAttempt.booking),
          loaded.copyWith(attempt: attempt),
          if (attempt == BookingAttempt.started) isA<ActivityState>().having((s) => s.next, 'next', isNotNull),
        ],
        verify: (_) => verify(() => activities.clearAttempt(activityId)).called(1),
      );
    }

    blocTest<ActivityBloc, ActivityState>(
      'session ended: sign in, key cleared',
      setUp: () =>
          when(() => activities.book(activityId)).thenThrow(const ApiException(status: 401, code: 'unauthenticated')),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      expect: () => [loaded.copyWith(attempt: BookingAttempt.booking), loaded.withEffect(ActivityEffect.signIn)],
      verify: (_) => verify(() => activities.clearAttempt(activityId)).called(1),
    );

    blocTest<ActivityBloc, ActivityState>(
      'already booked: reload, key cleared',
      setUp: () =>
          when(() => activities.book(activityId)).thenThrow(const ApiException(status: 409, code: 'already_booked')),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ActivityBookPressed()),
      verify: (_) {
        verify(() => activities.clearAttempt(activityId)).called(1);
        verify(() => activities.activity(activityId)).called(1);
      },
    );
  });
}
