// CodeEntryBloc (V-BLOC-1): typed codes, opening, unknown and rate-limited codes, offline.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/code_entry/code_entry.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/repositories/invite_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  late MockInviteRepository invites;
  late Completer<InviteView> slow;
  setUp(() {
    invites = MockInviteRepository();
    slow = Completer();
  });

  CodeEntryBloc build({String? initialError}) => CodeEntryBloc(inviteRepository: invites, initialError: initialError);

  test('an invite link that did not resolve shows its reason', () {
    expect(build(initialError: 'invalid').state.error, CodeEntryError.invalid);
    expect(build(initialError: 'limited').state.limited, isTrue);
    expect(build().state.error, isNull);
  });

  blocTest<CodeEntryBloc, CodeEntryState>(
    'a typed code is normalised; an incomplete one is not a code',
    build: build,
    act: (b) => b
      ..add(const CodeEntryChanged('k7-pq2'))
      ..add(const CodeEntryChanged('k7-pq2n')),
    expect: () => [const CodeEntryState(), const CodeEntryState(code: 'K7PQ2N')],
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'typing clears an unknown-code error but not the rate limit',
    build: () => build(initialError: 'limited'),
    act: (b) => b.add(const CodeEntryChanged('K7PQ2N')),
    expect: () => [const CodeEntryState(code: 'K7PQ2N', error: CodeEntryError.limited)],
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'a known code opens the invite',
    setUp: () => when(() => invites.invite('K7PQ2N')).thenAnswer((_) async => inviteView()),
    build: build,
    seed: () => const CodeEntryState(code: 'K7PQ2N'),
    act: (b) => b.add(const CodeEntrySubmitted()),
    expect: () => [
      const CodeEntryState(code: 'K7PQ2N', loading: true),
      const CodeEntryState(code: 'K7PQ2N', opened: 'K7PQ2N', opens: 1),
    ],
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'offline still opens the invite, which shows the saved copy',
    setUp: () => when(() => invites.invite('K7PQ2N')).thenThrow(const ApiException(message: 'network')),
    build: build,
    seed: () => const CodeEntryState(code: 'K7PQ2N'),
    act: (b) => b.add(const CodeEntrySubmitted()),
    expect: () => [
      const CodeEntryState(code: 'K7PQ2N', loading: true),
      const CodeEntryState(code: 'K7PQ2N', opened: 'K7PQ2N', opens: 1),
    ],
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'an unknown code stays here with the code kept',
    setUp: () => when(() => invites.invite('K7PQ2N')).thenThrow(const ApiException(status: 404, code: 'invalid_code')),
    build: build,
    seed: () => const CodeEntryState(code: 'K7PQ2N'),
    act: (b) => b.add(const CodeEntrySubmitted()),
    expect: () => [
      const CodeEntryState(code: 'K7PQ2N', loading: true),
      const CodeEntryState(code: 'K7PQ2N', error: CodeEntryError.invalid),
    ],
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'rate limited, and then nothing more is sent',
    setUp: () => when(() => invites.invite('K7PQ2N')).thenThrow(const ApiException(status: 429, code: 'rate_limited')),
    build: build,
    seed: () => const CodeEntryState(code: 'K7PQ2N'),
    act: (b) async {
      b.add(const CodeEntrySubmitted());
      await Future<void>.delayed(Duration.zero);
      b.add(const CodeEntrySubmitted());
    },
    expect: () => [
      const CodeEntryState(code: 'K7PQ2N', loading: true),
      const CodeEntryState(code: 'K7PQ2N', error: CodeEntryError.limited),
    ],
    verify: (_) => verify(() => invites.invite('K7PQ2N')).called(1),
  );

  blocTest<CodeEntryBloc, CodeEntryState>(
    'no code, no request; a second tap while opening is dropped',
    setUp: () => when(() => invites.invite('K7PQ2N')).thenAnswer((_) => slow.future),
    build: build,
    act: (b) async {
      b.add(const CodeEntrySubmitted());
      b.add(const CodeEntryChanged('K7PQ2N'));
      await Future<void>.delayed(Duration.zero);
      b
        ..add(const CodeEntrySubmitted())
        ..add(const CodeEntrySubmitted());
      await Future<void>.delayed(Duration.zero);
      slow.complete(inviteView());
    },
    verify: (_) => verify(() => invites.invite('K7PQ2N')).called(1),
  );
}
