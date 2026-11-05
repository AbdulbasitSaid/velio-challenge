// ClaimBloc (V-BLOC-1, V-CLM-1): the claimed invite, empty fields, success with the session adopted,
// each outcome and which ones clear the attempt key, Not you?, and a dropped double submit.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/claim/claim.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/invite_logic.dart';
import 'package:velio/repositories/invite_repository.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockInviteRepository extends Mock implements InviteRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class FakeUser extends Fake implements MemberPerson {
  @override
  String get id => 'u9';
  @override
  String get displayName => 'Zainab Okafor';
}

class FakeClaim extends Fake implements ClaimResponse {
  FakeClaim({this.token});
  @override
  final String? token;
  @override
  String get planId => planId_;
  @override
  MemberPerson get user => FakeUser();
}

const planId_ = '0190a6f2-0000-7000-8000-0000000000aa';
const code = 'K7PQ2N';
const profile = LocalProfile(userId: 'u9', displayName: 'Zainab Okafor', maskedContact: '+254 712 •••');

void main() {
  late MockInviteRepository invites;
  late MockSessionRepository session;

  setUp(() {
    invites = MockInviteRepository();
    session = MockSessionRepository();
    when(() => session.profile).thenReturn(null);
    when(() => invites.clearAttempt(code)).thenAnswer((_) async {});
  });

  ClaimBloc build() => ClaimBloc(inviteRepository: invites, sessionRepository: session, code: code);
  const guest = ClaimSubmitted(name: 'Zainab Okafor', contact: '+254712000000');

  test('a saved profile claims as that person', () {
    when(() => session.profile).thenReturn(profile);
    expect(build().state.signedIn, isTrue);
  });

  blocTest<ClaimBloc, ClaimState>(
    'shows the saved invite, then the API one; a failed fetch keeps the saved one',
    setUp: () {
      when(() => invites.cachedInvite(code)).thenAnswer((_) async => Cached(inviteView(), DateTime.utc(2026)));
      when(() => invites.invite(code)).thenThrow(const ApiException(message: 'network'));
    },
    build: build,
    act: (b) => b.add(const ClaimRequested()),
    expect: () => [isA<ClaimState>().having((s) => s.view?.code, 'view', code)],
  );

  blocTest<ClaimBloc, ClaimState>(
    'a new guest with empty fields: both errors, no claim',
    build: build,
    act: (b) => b.add(const ClaimSubmitted()),
    expect: () => [const ClaimState(signedIn: false, nameError: nameError, contactError: contactError)],
    verify: (_) => verifyNever(() => invites.claim(any())),
  );

  blocTest<ClaimBloc, ClaimState>(
    'claimed: the key is cleared, the new session adopted, then You’re in',
    setUp: () {
      when(() => invites.claim(code, displayName: 'Zainab Okafor', contact: '+254712000000'))
          .thenAnswer((_) async => FakeClaim(token: 'tok'));
      when(() => session.adopt('tok', userId: 'u9', displayName: 'Zainab Okafor', contact: '+254712000000'))
          .thenAnswer((_) async {});
    },
    build: build,
    act: (b) => b.add(guest),
    expect: () => [
      const ClaimState(signedIn: false, submitting: true),
      const ClaimState(signedIn: false, result: ClaimResult.claimed, planId: planId_, results: 1),
    ],
    verify: (_) {
      verify(() => invites.clearAttempt(code)).called(1);
      verify(() => session.adopt('tok', userId: 'u9', displayName: 'Zainab Okafor', contact: '+254712000000'))
          .called(1);
    },
  );

  blocTest<ClaimBloc, ClaimState>(
    'claiming as the saved person sends no name or contact',
    setUp: () {
      when(() => session.profile).thenReturn(profile);
      when(() => invites.claim(code)).thenAnswer((_) async => FakeClaim());
    },
    build: build,
    act: (b) => b.add(const ClaimSubmitted()),
    skip: 1,
    expect: () => [const ClaimState(signedIn: true, result: ClaimResult.claimed, planId: planId_, results: 1)],
    verify: (_) => verifyNever(
      () => session.adopt(
        any(),
        userId: any(named: 'userId'),
        displayName: any(named: 'displayName'),
        contact: any(named: 'contact'),
      ),
    ),
  );

  blocTest<ClaimBloc, ClaimState>(
    'a server or network failure keeps the key for Try again',
    setUp: () => when(
      () => invites.claim(
        code,
        displayName: any(named: 'displayName'),
        contact: any(named: 'contact'),
      ),
    ).thenThrow(const ApiException(message: 'network')),
    build: build,
    act: (b) => b.add(guest),
    skip: 1,
    expect: () => [
      isA<ClaimState>().having((s) => s.banner?.retry, 'retry', true).having((s) => s.blocked, 'blocked', false),
    ],
    verify: (_) => verifyNever(() => invites.clearAttempt(code)),
  );

  final finals = {
    'sold_out': (ClaimState s) => s.banner?.soldOut == true && s.blocked,
    'invalid_contact': (ClaimState s) => s.contactError == contactError,
    'validation_failed': (ClaimState s) => s.nameError == nameError,
    'already_booked': (ClaimState s) => s.result == ClaimResult.alreadyGoing && s.results == 1,
    'invite_expired': (ClaimState s) => s.result == ClaimResult.back && s.results == 1,
  };
  for (final MapEntry(key: c, value: check) in finals.entries) {
    blocTest<ClaimBloc, ClaimState>(
      '$c is final: the key is cleared',
      setUp: () => when(
        () => invites.claim(
          code,
          displayName: any(named: 'displayName'),
          contact: any(named: 'contact'),
        ),
      ).thenThrow(ApiException(status: 409, code: c)),
      build: build,
      act: (b) => b.add(guest),
      skip: 1,
      expect: () => [predicate<ClaimState>(check)],
      verify: (_) => verify(() => invites.clearAttempt(code)).called(1),
    );
  }

  blocTest<ClaimBloc, ClaimState>(
    'a second Confirm while claiming is dropped',
    setUp: () {
      final slow = Completer<ClaimResponse>();
      when(
        () => invites.claim(
          code,
          displayName: any(named: 'displayName'),
          contact: any(named: 'contact'),
        ),
      ).thenAnswer((_) => slow.future);
      Future<void>.delayed(const Duration(milliseconds: 10), () => slow.complete(FakeClaim()));
    },
    build: build,
    act: (b) => b
      ..add(guest)
      ..add(guest),
    wait: const Duration(milliseconds: 20),
    verify: (_) => verify(
      () => invites.claim(
        code,
        displayName: any(named: 'displayName'),
        contact: any(named: 'contact'),
      ),
    ).called(1),
  );

  blocTest<ClaimBloc, ClaimState>(
    'Not you? signs out and shows the two fields',
    setUp: () {
      when(() => session.profile).thenReturn(profile);
      when(() => session.signOut()).thenAnswer((_) async {});
    },
    build: build,
    act: (b) => b.add(const ClaimNotYouPressed()),
    expect: () => [const ClaimState(signedIn: false)],
    verify: (_) => verify(() => session.signOut()).called(1),
  );
}
