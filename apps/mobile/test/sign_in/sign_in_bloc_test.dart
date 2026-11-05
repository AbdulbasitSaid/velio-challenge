// SignInBloc (V-BLOC-1): empty fields, success with only app paths as next, and each failure.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/invite_logic.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio/sign_in/sign_in.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository session;
  setUp(() => session = MockSessionRepository());

  const submit = SignInSubmitted(name: ' Zainab Okafor ', contact: ' +254712000000 ');

  blocTest<SignInBloc, SignInState>(
    'empty fields: both errors, no request',
    build: () => SignInBloc(sessionRepository: session),
    act: (b) => b.add(const SignInSubmitted(name: ' ', contact: '')),
    expect: () => [const SignInState(nameError: nameError, contactError: contactError)],
    verify: (_) => verifyNever(() => session.signIn(any(), any())),
  );

  blocTest<SignInBloc, SignInState>(
    'signed in: on to next, trimmed',
    setUp: () => when(() => session.signIn('Zainab Okafor', '+254712000000')).thenAnswer((_) async {}),
    build: () => SignInBloc(sessionRepository: session, next: '/plans/p1'),
    act: (b) => b.add(submit),
    expect: () => [const SignInState(), const SignInState(busy: true), const SignInState(destination: '/plans/p1')],
  );

  for (final next in [null, '//evil.example', 'https://evil.example']) {
    blocTest<SignInBloc, SignInState>(
      'next "$next" falls back to My plans',
      setUp: () => when(() => session.signIn(any(), any())).thenAnswer((_) async {}),
      build: () => SignInBloc(sessionRepository: session, next: next),
      act: (b) => b.add(submit),
      skip: 2,
      expect: () => [const SignInState(destination: '/me/plans')],
    );
  }

  final failures = {
    const ApiException(status: 400, code: 'invalid_contact'): const SignInState(
      contactError: 'Enter a phone number with country code, or a full email address.',
    ),
    const ApiException(status: 400, code: 'validation_failed'): const SignInState(nameError: nameError),
    const ApiException(message: 'network'): const SignInState(error: 'Check your connection and try again.'),
    const ApiException(status: 500, code: 'internal'): const SignInState(error: 'We couldn’t sign you in.'),
  };
  for (final MapEntry(key: e, value: s) in failures.entries) {
    blocTest<SignInBloc, SignInState>(
      'fails with ${e.code ?? 'network'}',
      setUp: () => when(() => session.signIn(any(), any())).thenThrow(e),
      build: () => SignInBloc(sessionRepository: session),
      act: (b) => b.add(submit),
      skip: 2,
      expect: () => [s],
    );
  }
}
