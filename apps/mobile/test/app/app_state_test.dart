// App-wide state (V-BLOC-1; FR-011–FR-013): SessionBloc, RoleCubit, ConnectivityCubit.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/connectivity/cubit/connectivity_cubit.dart';
import 'package:velio/repositories/connectivity_repository.dart';
import 'package:velio/repositories/preferences_repository.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio/role/cubit/role_cubit.dart';
import 'package:velio/session/bloc/session_bloc.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

void main() {
  const me = LocalProfile(userId: 'u1', displayName: 'Zainab Okafor', maskedContact: '+254 712 •••');

  group('SessionBloc', () {
    late MockSessionRepository session;
    late StreamController<LocalProfile?> changes;

    setUp(() {
      session = MockSessionRepository();
      changes = StreamController<LocalProfile?>.broadcast();
      when(() => session.profile).thenReturn(null);
      when(() => session.changes).thenAnswer((_) => changes.stream);
    });

    test('starts from the stored profile', () {
      when(() => session.profile).thenReturn(me);
      expect(SessionBloc(sessionRepository: session).state.signedIn, isTrue);
    });

    blocTest<SessionBloc, SessionState>(
      'follows sign-in and sign-out',
      build: () => SessionBloc(sessionRepository: session),
      act: (b) async {
        b.add(const SessionSubscriptionRequested());
        await pumpEventQueue();
        changes
          ..add(me)
          ..add(null);
      },
      expect: () => [const SessionState(me), const SessionState(null)],
    );
  });

  group('RoleCubit', () {
    late MockPreferencesRepository prefs;
    setUp(() {
      prefs = MockPreferencesRepository();
      when(() => prefs.saveRole(any())).thenAnswer((_) async {});
    });
    setUpAll(() => registerFallbackValue(Role.booker));

    test('starts from the saved role', () {
      expect(RoleCubit(preferencesRepository: prefs, initial: Role.host).state, Role.host);
    });

    blocTest<RoleCubit, Role>(
      'a switch is shown and remembered',
      build: () => RoleCubit(preferencesRepository: prefs, initial: Role.booker),
      act: (c) => c.changed(Role.host),
      expect: () => [Role.host],
      verify: (_) => verify(() => prefs.saveRole(Role.host)).called(1),
    );
  });

  group('ConnectivityCubit', () {
    blocTest<ConnectivityCubit, bool>(
      'online until the platform says otherwise',
      build: () =>
          ConnectivityCubit(connectivityRepository: ConnectivityRepository(online: Stream.fromIterable([false, true]))),
      expect: () => [false, true],
    );
  });
}
