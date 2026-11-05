// MyPlansBloc (V-BLOC-1, V-MY-1, V-OFF-1): signed out, the saved list then the API's, offline from
// the saved list with its time, failures, the tab, and a reload on sign-in or sign-out.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/my_plans/my_plans.dart';
import 'package:velio/repositories/plan_repository.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio_api/velio_api.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockPlanRepository plans;
  late MockSessionRepository session;
  late StreamController<LocalProfile?> changes;
  final saved = MyPlans(upcoming: const [], past: const []);
  final fresh = MyPlans(upcoming: const [], past: const []);
  final savedAt = DateTime.utc(2026, 11, 4, 11, 45);

  setUp(() {
    plans = MockPlanRepository();
    session = MockSessionRepository();
    changes = StreamController<LocalProfile?>.broadcast();
    when(() => session.signedIn).thenReturn(true);
    when(() => session.changes).thenAnswer((_) => changes.stream);
    when(() => plans.cachedMyPlans()).thenAnswer((_) async => null);
    when(() => plans.myPlans()).thenAnswer((_) async => fresh);
  });

  MyPlansBloc build() => MyPlansBloc(planRepository: plans, sessionRepository: session);

  blocTest<MyPlansBloc, MyPlansState>(
    'signed out: nothing is fetched',
    setUp: () => when(() => session.signedIn).thenReturn(false),
    build: build,
    act: (b) => b.add(const MyPlansRequested()),
    expect: () => [const MyPlansState(signedIn: false, loading: true), const MyPlansState(signedIn: false)],
    verify: (_) => verifyNever(() => plans.myPlans()),
  );

  blocTest<MyPlansBloc, MyPlansState>(
    'the saved list first, then the API’s',
    setUp: () => when(() => plans.cachedMyPlans()).thenAnswer((_) async => Cached(saved, savedAt)),
    build: build,
    act: (b) => b.add(const MyPlansRequested()),
    expect: () => [
      const MyPlansState(signedIn: true, loading: true),
      MyPlansState(signedIn: true, loading: true, plans: saved),
      MyPlansState(signedIn: true, plans: fresh),
    ],
  );

  blocTest<MyPlansBloc, MyPlansState>(
    'offline: the saved list with when it was saved',
    setUp: () {
      when(() => plans.cachedMyPlans()).thenAnswer((_) async => Cached(saved, savedAt));
      when(() => plans.myPlans()).thenThrow(const ApiException(message: 'network'));
    },
    build: build,
    act: (b) => b.add(const MyPlansRequested()),
    skip: 2,
    expect: () => [MyPlansState(signedIn: true, plans: saved, offline: true, cachedAt: savedAt)],
  );

  for (final (e, error) in [
    (const ApiException(message: 'network'), LoadError.offline),
    (const ApiException(status: 401, code: 'unauthorized'), LoadError.signIn),
    (const ApiException(status: 500, code: 'internal'), LoadError.server),
  ]) {
    blocTest<MyPlansBloc, MyPlansState>(
      'no saved list and ${e.status ?? 'network'}: ${error.name}',
      setUp: () => when(() => plans.myPlans()).thenThrow(e),
      build: build,
      act: (b) => b.add(const MyPlansRequested()),
      skip: 1,
      expect: () => [MyPlansState(signedIn: true, error: error)],
    );
  }

  blocTest<MyPlansBloc, MyPlansState>(
    'Past and Upcoming',
    build: build,
    act: (b) => b.add(const MyPlansTabChanged(past: true)),
    expect: () => [const MyPlansState(signedIn: true, past: true)],
  );

  blocTest<MyPlansBloc, MyPlansState>(
    'signing in or out reloads from scratch',
    build: build,
    seed: () => MyPlansState(signedIn: true, plans: saved, past: true),
    act: (b) async {
      b.add(const MyPlansSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      changes.add(null);
    },
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const MyPlansState(signedIn: true, past: true, loading: true),
      MyPlansState(signedIn: true, past: true, plans: fresh),
    ],
  );
}
