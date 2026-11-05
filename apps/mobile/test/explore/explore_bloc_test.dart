// ExploreBloc (V-BLOC-1): the first community or a named one, no communities, failures, live counts
// with the version gate per activity, the refresh, and the List / Map toggle.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/live.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/explore/explore.dart';
import 'package:velio/repositories/activity_repository.dart';
import 'package:velio/repositories/live_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockLiveRepository extends Mock implements LiveRepository {}

const soldOutId = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e10';

void main() {
  late MockActivityRepository activities;
  late MockLiveRepository live;
  late StreamController<LiveUpdate> updates;
  final page = CommunityPage.fromJson(communityPageJson());
  final counts = {
    activityId: const LiveCount(spotsLeft: 6, version: 3),
    soldOutId: const LiveCount(spotsLeft: 0, version: 3),
  };
  final loaded = ExploreState(status: ExploreStatus.success, page: page, counts: counts);

  setUp(() {
    activities = MockActivityRepository();
    live = MockLiveRepository();
    updates = StreamController<LiveUpdate>();
    when(() => activities.communities()).thenAnswer(
      (_) async => CommunityList.fromJson({
        'communities': [communityJson()],
      }),
    );
    when(() => activities.community('explore-kenya')).thenAnswer((_) async => page);
    when(() => live.status).thenReturn(RealtimeStatus.live);
    when(() => live.watch(any())).thenAnswer((_) => updates.stream);
  });

  ExploreBloc build({String? slug}) => ExploreBloc(activityRepository: activities, liveRepository: live, slug: slug);

  group('load', () {
    blocTest<ExploreBloc, ExploreState>(
      'Explore opens the first community, then follows every card',
      build: build,
      act: (b) => b.add(const ExploreRequested()),
      expect: () => [loaded, loaded.copyWith(realtime: RealtimeStatus.live)],
      verify: (b) {
        verify(() => live.watch(['activity:$activityId', 'activity:$soldOutId'])).called(1);
        expect(b.state.open.map((a) => a.id), [activityId]);
      },
    );

    blocTest<ExploreBloc, ExploreState>(
      'a named community skips the list',
      build: () => build(slug: 'explore-kenya'),
      act: (b) => b.add(const ExploreRequested()),
      verify: (_) => verifyNever(() => activities.communities()),
    );

    blocTest<ExploreBloc, ExploreState>(
      'no communities at all',
      setUp: () =>
          when(() => activities.communities())
              .thenAnswer((_) async => CommunityList.fromJson({'communities': <Object>[]})),
      build: build,
      act: (b) => b.add(const ExploreRequested()),
      expect: () => [const ExploreState(status: ExploreStatus.none)],
    );

    for (final (error, expected) in [
      (const ApiException(status: 404, code: 'not_found'), LoadError.notFound),
      (const ApiException(status: 400, code: 'validation_failed'), LoadError.notFound),
      (const ApiException(message: 'network'), LoadError.offline),
      (const ApiException(status: 500, code: 'internal'), LoadError.server),
    ]) {
      blocTest<ExploreBloc, ExploreState>(
        '${error.status ?? 'network'} is ${expected.name}',
        setUp: () => when(() => activities.community('explore-kenya')).thenThrow(error),
        build: () => build(slug: 'explore-kenya'),
        act: (b) => b.add(const ExploreRequested()),
        expect: () => [ExploreState(status: ExploreStatus.failure, error: expected)],
      );
    }

    blocTest<ExploreBloc, ExploreState>(
      'pull to refresh keeps the page and completes',
      build: build,
      seed: () => loaded,
      act: (b) async {
        final done = Completer<void>();
        b.add(ExploreRequested(done: done));
        await done.future;
      },
      expect: () => <ExploreState>[],
      verify: (_) => verifyNever(() => live.watch(any())),
    );
  });

  group('live', () {
    blocTest<ExploreBloc, ExploreState>(
      'the version gate per activity; other activities are ignored',
      build: build,
      seed: () => loaded,
      act: (b) => b
        ..add(const ExploreLiveUpdated(LiveSpotsChanged(activityId, 9, 2)))
        ..add(const ExploreLiveUpdated(LiveSpotsChanged(activityId, 5, 4)))
        ..add(const ExploreLiveUpdated(LiveSpotsChanged('other', 1, 9))),
      expect: () => [
        loaded.copyWith(counts: {...counts, activityId: const LiveCount(spotsLeft: 5, version: 4, changed: true)}),
      ],
      verify: (_) {
        verify(() => live.rendered(activityId, 4)).called(1);
        verifyNever(() => live.rendered(activityId, 2));
      },
    );

    blocTest<ExploreBloc, ExploreState>(
      'a refresh applies the fetched counts',
      setUp: () => when(() => activities.community('explore-kenya')).thenAnswer(
        (_) async => CommunityPage.fromJson({
          ...communityPageJson(),
          'activities': [
            {...cardJson(spotsLeft: 2), 'version': 7},
          ],
        }),
      ),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ExploreLiveUpdated(LiveRefreshRequested())),
      expect: () => [
        loaded.copyWith(counts: {...counts, activityId: const LiveCount(spotsLeft: 2, version: 7)}),
      ],
    );

    blocTest<ExploreBloc, ExploreState>(
      'a failed refresh changes nothing',
      setUp: () => when(() => activities.community('explore-kenya')).thenThrow(const ApiException(message: 'network')),
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ExploreLiveUpdated(LiveRefreshRequested())),
      expect: () => <ExploreState>[],
    );

    blocTest<ExploreBloc, ExploreState>(
      'reconnecting',
      build: build,
      seed: () => loaded,
      act: (b) => b.add(const ExploreLiveUpdated(LiveStatusChanged(RealtimeStatus.reconnecting))),
      expect: () => [loaded.copyWith(realtime: RealtimeStatus.reconnecting)],
    );
  });

  blocTest<ExploreBloc, ExploreState>(
    'List / Map toggle',
    build: build,
    seed: () => loaded,
    act: (b) => b.add(const ExploreViewToggled(true)),
    expect: () => [loaded.copyWith(showMap: true)],
  );
}
