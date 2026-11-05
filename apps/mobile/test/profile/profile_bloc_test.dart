// ProfileBloc (V-BLOC-1): load, not found, offline and retry.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/profile/profile.dart';
import 'package:velio/repositories/plan_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late MockPlanRepository plans;
  final profile = Profile.fromJson({'person': person('u1', 'Tunde A.'), 'memberSince': '2023-06', 'hosting': const []});

  setUp(() => plans = MockPlanRepository());

  ProfileBloc build() => ProfileBloc(planRepository: plans, userId: 'u1');

  blocTest<ProfileBloc, ProfileState>(
    'loads the profile',
    setUp: () => when(() => plans.profile('u1')).thenAnswer((_) async => profile),
    build: build,
    act: (b) => b.add(const ProfileRequested()),
    expect: () => [const ProfileState(), ProfileState(status: ProfileStatus.success, profile: profile)],
  );

  blocTest<ProfileBloc, ProfileState>(
    '404 is not found',
    setUp: () => when(() => plans.profile('u1')).thenThrow(const ApiException(status: 404, code: 'not_found')),
    build: build,
    act: (b) => b.add(const ProfileRequested()),
    expect: () => [const ProfileState(), const ProfileState(status: ProfileStatus.failure, error: LoadError.notFound)],
  );

  blocTest<ProfileBloc, ProfileState>(
    'a network failure is offline, and Try again loads again',
    setUp: () => when(() => plans.profile('u1')).thenThrow(const ApiException(message: 'network')),
    build: build,
    act: (b) => b
      ..add(const ProfileRequested())
      ..add(const ProfileRequested()),
    expect: () => [
      const ProfileState(),
      const ProfileState(status: ProfileStatus.failure, error: LoadError.offline),
      const ProfileState(),
      const ProfileState(status: ProfileStatus.failure, error: LoadError.offline),
    ],
    verify: (_) => verify(() => plans.profile('u1')).called(2),
  );
}
