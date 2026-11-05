// PlanBloc (V-BLOC-1, V-PLAN-1): the Plan with its activity, each failure, live spots, and a refetch
// when the Plan changes (rule 5).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/live.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/plan/plan.dart';
import 'package:velio/repositories/live_repository.dart';
import 'package:velio/repositories/plan_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

class MockLiveRepository extends Mock implements LiveRepository {}

void main() {
  late MockPlanRepository plans;
  late MockLiveRepository live;
  late StreamController<LiveUpdate> updates;
  final plan = PlanView.fromJson(planJson());
  final activity = PublicActivity.fromJson(activityJson());

  setUp(() {
    plans = MockPlanRepository();
    live = MockLiveRepository();
    updates = StreamController<LiveUpdate>();
    when(() => live.status).thenReturn(RealtimeStatus.connecting);
    when(() => live.watch(any())).thenAnswer((_) => updates.stream);
    when(() => plans.plan(planId)).thenAnswer((_) async => plan);
    when(() => plans.activity(activityId)).thenAnswer((_) async => activity);
  });

  PlanBloc build() => PlanBloc(planRepository: plans, liveRepository: live, planId: planId);

  blocTest<PlanBloc, PlanState>(
    'loads the Plan and its activity, then follows both topics',
    build: build,
    act: (b) => b.add(const PlanRequested()),
    wait: Duration.zero,
    expect: () => [
      const PlanState(loading: true),
      PlanState(
        plan: plan,
        activity: activity,
        live: LiveCount(spotsLeft: activity.spotsLeft, version: activity.version),
      ),
    ],
    verify: (_) => verify(() => live.watch(['activity:$activityId', 'plan:$planId'])).called(1),
  );

  final errors = {
    const ApiException(status: 401, code: 'unauthorized'): LoadError.signIn,
    const ApiException(status: 403, code: 'forbidden'): LoadError.notFound,
    const ApiException(status: 404, code: 'not_found'): LoadError.notFound,
    const ApiException(message: 'network'): LoadError.offline,
    const ApiException(status: 500, code: 'internal'): LoadError.server,
  };
  for (final MapEntry(key: e, value: error) in errors.entries) {
    blocTest<PlanBloc, PlanState>(
      '${e.status ?? 'network'} is ${error.name}',
      setUp: () => when(() => plans.plan(planId)).thenThrow(e),
      build: build,
      act: (b) => b.add(const PlanRequested()),
      expect: () => [const PlanState(loading: true), PlanState(error: error)],
      verify: (_) => verifyNever(() => live.watch(any())),
    );
  }

  blocTest<PlanBloc, PlanState>(
    'live: a newer count is shown and acked; a Plan change refetches',
    build: build,
    act: (b) async {
      b.add(const PlanRequested());
      await Future<void>.delayed(Duration.zero);
      updates
        ..add(LiveSpotsChanged(activityId, 2, activity.version + 1))
        ..add(const LivePlanChanged(planId));
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.live, LiveCount(spotsLeft: 2, version: activity.version + 1, changed: true));
      verify(() => live.rendered(activityId, activity.version + 1)).called(1);
      verify(() => plans.plan(planId)).called(2);
    },
  );
}
