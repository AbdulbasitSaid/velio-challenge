// InviteBloc (V-BLOC-1, V-INV-1, V-OFF-1): the saved copy, then the API's; offline from the saved copy
// with its time; errors; live spots with the version gate; the beacon once; next steps when the
// invite can't be claimed.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/invite_logic.dart';
import 'package:velio/domain/live.dart';
import 'package:velio/invite/invite.dart';
import 'package:velio/repositories/invite_repository.dart';
import 'package:velio/repositories/live_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockInviteRepository extends Mock implements InviteRepository {}

class MockLiveRepository extends Mock implements LiveRepository {}

const code = 'K7PQ2N';
final savedAt = DateTime.utc(2026, 11, 4, 12);

void main() {
  late MockInviteRepository invites;
  late MockLiveRepository live;
  late StreamController<LiveUpdate> updates;
  final view = inviteView();
  final a = view.activity;

  setUp(() {
    invites = MockInviteRepository();
    live = MockLiveRepository();
    updates = StreamController<LiveUpdate>();
    when(() => live.status).thenReturn(RealtimeStatus.connecting);
    when(() => live.watch(any())).thenAnswer((_) => updates.stream);
    when(() => invites.cachedInvite(code)).thenAnswer((_) async => null);
    when(() => invites.invite(code)).thenAnswer((_) async => view);
    when(() => invites.open(code)).thenAnswer((_) async {});
    when(() => invites.nextSteps(any()))
        .thenAnswer((_) async => NextSteps(hostOtherDates: const [], moreInCommunity: const []));
  });

  InviteBloc build() => InviteBloc(inviteRepository: invites, liveRepository: live, code: code);

  blocTest<InviteBloc, InviteState>(
    'loads, then follows the activity live',
    build: build,
    act: (b) => b.add(const InviteRequested()),
    wait: Duration.zero,
    expect: () => [
      const InviteState(),
      isA<InviteState>()
          .having((s) => s.view, 'view', view)
          .having((s) => s.live, 'live', LiveCount(spotsLeft: a.spotsLeft, version: a.version)),
    ],
    verify: (_) => verify(() => live.watch(['activity:${a.id}'])).called(1),
  );

  blocTest<InviteBloc, InviteState>(
    'offline with a saved copy: shows it with when it was saved, and doesn’t follow live',
    setUp: () {
      when(() => invites.cachedInvite(code)).thenAnswer((_) async => Cached(view, savedAt));
      when(() => invites.invite(code)).thenThrow(const ApiException(message: 'network'));
    },
    build: build,
    act: (b) => b.add(const InviteRequested()),
    skip: 2,
    expect: () => [
      isA<InviteState>()
          .having((s) => s.offline, 'offline', true)
          .having((s) => s.cachedAt, 'cachedAt', savedAt)
          .having((s) => s.live, 'live', isNull)
          .having((s) => s.screen, 'screen', isA<OpenScreen>()),
    ],
    verify: (_) => verifyNever(() => live.watch(any())),
  );

  final errors = {
    const ApiException(message: 'network'): InviteError.offline,
    const ApiException(status: 404, code: 'invalid_code'): InviteError.invalid,
    const ApiException(status: 404, code: 'not_found'): InviteError.invalid,
    const ApiException(status: 429, code: 'rate_limited'): InviteError.limited,
    const ApiException(status: 500, code: 'internal'): InviteError.server,
  };
  for (final MapEntry(key: e, value: error) in errors.entries) {
    blocTest<InviteBloc, InviteState>(
      'no saved copy and ${e.code ?? 'network'}: ${error.name}',
      setUp: () => when(() => invites.invite(code)).thenThrow(e),
      build: build,
      act: (b) => b.add(const InviteRequested()),
      expect: () => [const InviteState(), InviteState(error: error)],
    );
  }

  blocTest<InviteBloc, InviteState>(
    'live spots: only newer versions, each one acked; refetch on resync; status for the pill',
    build: build,
    act: (b) async {
      b.add(const InviteRequested());
      await Future<void>.delayed(Duration.zero);
      updates
        ..add(LiveSpotsChanged(a.id, 3, a.version + 1))
        ..add(LiveSpotsChanged(a.id, 9, a.version)) // older: ignored
        ..add(const LiveStatusChanged(RealtimeStatus.reconnecting))
        ..add(const LiveRefreshRequested());
    },
    wait: const Duration(milliseconds: 10),
    skip: 2,
    expect: () => [
      isA<InviteState>().having((s) => s.live, 'live', LiveCount(spotsLeft: 3, version: a.version + 1, changed: true)),
      isA<InviteState>().having((s) => s.realtime, 'realtime', RealtimeStatus.reconnecting),
    ],
    verify: (_) {
      verify(() => live.rendered(a.id, a.version + 1)).called(1);
      verify(() => invites.invite(code)).called(2);
    },
  );

  blocTest<InviteBloc, InviteState>(
    'a refetch that fails for want of a network marks the invite offline',
    build: build,
    act: (b) async {
      b.add(const InviteRequested());
      await Future<void>.delayed(Duration.zero);
      when(() => invites.invite(code)).thenThrow(const ApiException(message: 'network'));
      updates.add(const LiveRefreshRequested());
    },
    wait: const Duration(milliseconds: 10),
    skip: 2,
    expect: () => [isA<InviteState>().having((s) => s.offline, 'offline', true)],
  );

  blocTest<InviteBloc, InviteState>(
    'the open beacon is sent once',
    build: build,
    act: (b) => b
      ..add(const InviteShown())
      ..add(const InviteShown()),
    verify: (_) => verify(() => invites.open(code)).called(1),
  );

  blocTest<InviteBloc, InviteState>(
    'sold out on load: next steps load once',
    setUp: () =>
        when(() => invites.invite(code)).thenAnswer((_) async => inviteView(activity: activityJson(spotsLeft: 0))),
    build: build,
    act: (b) => b.add(const InviteRequested()),
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.screen, isA<SoldOutScreen>());
      expect(b.state.next, isNotNull);
      verify(() => invites.nextSteps(a.id)).called(1);
    },
  );

  blocTest<InviteBloc, InviteState>(
    'an open invite needs no next steps',
    build: build,
    act: (b) => b.add(const InviteRequested()),
    wait: const Duration(milliseconds: 10),
    verify: (_) => verifyNever(() => invites.nextSteps(any())),
  );
}
