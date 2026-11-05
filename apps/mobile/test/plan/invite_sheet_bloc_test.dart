// InviteSheetBloc (V-BLOC-1, V-PLAN-1): the vouch (name required, the contact kept out of the
// message), the public link, resume, and their failures.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:velio/domain/api_exception.dart';
import 'package:velio/plan/plan.dart';
import 'package:velio/repositories/plan_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

class FakeInvite extends Fake implements Invite {
  FakeInvite({this.paused = false});
  @override
  final bool paused;
  @override
  String get code => 'P4BLIC';
  @override
  String get link => 'https://velio.test/i/P4BLIC';
}

void main() {
  late MockPlanRepository plans;
  final plan = PlanView.fromJson(planJson());
  final activity = PublicActivity.fromJson(activityJson());

  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('en_GB');
  });
  setUp(() => plans = MockPlanRepository());

  InviteSheetBloc build() => InviteSheetBloc(planRepository: plans, plan: plan, activity: activity);

  blocTest<InviteSheetBloc, InviteSheetState>(
    'choosing a vouch opens its form',
    build: build,
    act: (b) => b.add(const InviteSheetVouchChosen()),
    expect: () => [const InviteSheetState(step: InviteSheetStep.vouch)],
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'a vouch needs a name',
    build: build,
    act: (b) => b.add(const InviteSheetVouchSubmitted(name: ' ')),
    expect: () => [const InviteSheetState(nameError: 'Add their name, so the invite is addressed to them.')],
    verify: (_) => verifyNever(() => plans.createInvite(any(), any())),
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'a vouch is created and its message has the link but not the contact',
    setUp: () => when(() => plans.createInvite(planId, any())).thenAnswer((_) async => FakeInvite()),
    build: build,
    act: (b) => b.add(const InviteSheetVouchSubmitted(name: 'Wanjiru', contact: 'w@example.com', note: ' ')),
    skip: 1,
    expect: () => [
      isA<InviteSheetState>().having(
        (s) => s.message,
        'message',
        allOf(contains('https://velio.test/i/P4BLIC'), isNot(contains('w@example.com'))),
      ),
    ],
    verify: (_) => verify(
      () => plans.createInvite(planId, {
        'rail': 'vouch',
        'inviteeName': 'Wanjiru',
        'contact': 'w@example.com',
        'note': null,
      }),
    ).called(1),
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'an invalid contact is shown on its field',
    setUp: () =>
        when(() => plans.createInvite(planId, any()))
            .thenThrow(const ApiException(status: 400, code: 'invalid_contact')),
    build: build,
    act: (b) => b.add(const InviteSheetVouchSubmitted(name: 'Wanjiru', contact: 'x')),
    skip: 1,
    expect: () => [
      const InviteSheetState(contactError: 'Enter a full phone number with country code, or an email address.'),
    ],
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'the public link',
    setUp: () => when(() => plans.createInvite(planId, {'rail': 'public'})).thenAnswer((_) async => FakeInvite()),
    build: build,
    act: (b) => b.add(const InviteSheetLinkRequested()),
    expect: () => [
      const InviteSheetState(step: InviteSheetStep.link, busy: true),
      isA<InviteSheetState>().having((s) => s.link?.code, 'link', 'P4BLIC').having((s) => s.busy, 'busy', false),
    ],
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'the link offline',
    setUp: () => when(() => plans.createInvite(planId, any())).thenThrow(const ApiException(message: 'network')),
    build: build,
    act: (b) => b.add(const InviteSheetLinkRequested()),
    skip: 1,
    expect: () => [const InviteSheetState(step: InviteSheetStep.link, error: 'Check your connection and try again.')],
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'resume a paused link, then fetch it again',
    setUp: () {
      when(() => plans.createInvite(planId, any())).thenAnswer((_) async => FakeInvite());
      when(() => plans.resumeInvite('P4BLIC')).thenAnswer((_) async {});
    },
    build: build,
    seed: () => InviteSheetState(step: InviteSheetStep.link, link: FakeInvite(paused: true)),
    act: (b) => b.add(const InviteSheetResumePressed()),
    verify: (_) {
      verify(() => plans.resumeInvite('P4BLIC')).called(1);
      verify(() => plans.createInvite(planId, {'rail': 'public'})).called(1);
    },
  );

  blocTest<InviteSheetBloc, InviteSheetState>(
    'a failed resume says so',
    setUp: () => when(() => plans.resumeInvite('P4BLIC')).thenThrow(const ApiException(status: 500, code: 'internal')),
    build: build,
    seed: () => InviteSheetState(step: InviteSheetStep.link, link: FakeInvite(paused: true)),
    act: (b) => b.add(const InviteSheetResumePressed()),
    skip: 1,
    expect: () => [isA<InviteSheetState>().having((s) => s.error, 'error', 'We couldn’t resume the link.')],
  );
}
