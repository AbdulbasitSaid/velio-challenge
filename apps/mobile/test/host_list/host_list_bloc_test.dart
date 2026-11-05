// HostListBloc (V-BLOC-1): signed out, load, its failures, Upcoming / Past, and the reload when who's
// signed in changes.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/host_list/host_list.dart';
import 'package:velio/repositories/host_repository.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockHostRepository extends Mock implements HostRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockHostRepository host;
  late MockSessionRepository session;
  late StreamController<LocalProfile?> changes;
  final list = HostActivityList.fromJson(hostListJson());

  setUp(() {
    host = MockHostRepository();
    session = MockSessionRepository();
    changes = StreamController<LocalProfile?>.broadcast();
    when(() => session.changes).thenAnswer((_) => changes.stream);
    when(() => session.signedIn).thenReturn(true);
  });
  tearDown(() => changes.close());

  HostListBloc build() => HostListBloc(hostRepository: host, sessionRepository: session);

  blocTest<HostListBloc, HostListState>(
    'signed out: nothing is loaded and sign-in is asked for',
    setUp: () => when(() => session.signedIn).thenReturn(false),
    build: build,
    act: (b) => b.add(const HostListRequested()),
    expect: () => <HostListState>[],
    verify: (b) {
      expect(b.state.needsSignIn, isTrue);
      verifyNever(() => host.hostActivities());
    },
  );

  blocTest<HostListBloc, HostListState>(
    'loads the list, then Past',
    setUp: () => when(() => host.hostActivities()).thenAnswer((_) async => list),
    build: build,
    act: (b) => b
      ..add(const HostListRequested())
      ..add(const HostListPastToggled(true)),
    expect: () => [HostListState(signedIn: true, data: list), HostListState(signedIn: true, data: list, past: true)],
    verify: (b) => expect(b.state.items, list.past),
  );

  blocTest<HostListBloc, HostListState>(
    'a failure keeps the error; 401 asks to sign in',
    setUp: () => when(() => host.hostActivities()).thenThrow(const ApiException(status: 401, code: 'unauthenticated')),
    build: build,
    act: (b) => b.add(const HostListRequested()),
    expect: () => [const HostListState(signedIn: true, error: LoadError.signIn)],
    verify: (b) => expect(b.state.needsSignIn, isTrue),
  );

  blocTest<HostListBloc, HostListState>(
    'offline, and pull to refresh completes',
    setUp: () => when(() => host.hostActivities()).thenThrow(const ApiException(message: 'network')),
    build: build,
    act: (b) async {
      final done = Completer<void>();
      b.add(HostListRequested(done: done));
      await done.future;
    },
    expect: () => [const HostListState(signedIn: true, error: LoadError.offline)],
  );

  blocTest<HostListBloc, HostListState>(
    'signing out clears the list',
    setUp: () => when(() => host.hostActivities()).thenAnswer((_) async => list),
    build: build,
    act: (b) async {
      b
        ..add(const HostListRequested())
        ..add(const HostListSessionSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      when(() => session.signedIn).thenReturn(false);
      changes.add(null);
    },
    expect: () => [HostListState(signedIn: true, data: list), const HostListState(signedIn: false)],
  );
}
