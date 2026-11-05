// ActivityFormBloc (V-BLOC-1): load (create and edit, not the host), validation on submit, edits
// clearing the API's errors, the photo pipeline, Publish, the changed-only Save, and the
// `location_locked` / `capacity_below_bookings` mapping with a snapshot refresh (REQUIREMENTS §7).
import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:velio/activity_form/activity_form.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/host_form.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/repositories/host_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockHostRepository extends Mock implements HostRepository {}

const _loc = PickedLocation(placeId: 'p1', venueName: 'Boat Club', addressText: 'Moi Rd', lat: -0.77, lng: 36.43);

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<String, Object?>{});
  });

  late MockHostRepository host;
  final communities = CommunityList.fromJson({
    'communities': [communityJson()],
  });
  // With a photo, so an unchanged edit form is valid.
  final hostedJson = {
    ...activityJson(viewer: {'isHost': true, 'booking': null}),
    'photoUrl': '/photos/u/k.jpg',
  };
  final hosted = PublicActivity.fromJson(hostedJson);
  final unbooked = PublicActivity.fromJson({
    ...hostedJson,
    'members': {...(activityJson()['members'] as Map<String, dynamic>), 'count': 0},
  });
  final now = DateTime.utc(2026, 11, 4, 12, 10);

  setUp(() {
    host = MockHostRepository();
    when(() => host.communities()).thenAnswer((_) async => communities);
  });

  ActivityFormBloc build({String? id}) => ActivityFormBloc(hostRepository: host, id: id, clock: () => now);
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  /// A create form with everything filled in.
  Future<ActivityFormBloc> filled() async {
    final b = build()..add(const ActivityFormRequested());
    await settle();
    b
      ..add(const ActivityFormTitleChanged('Sunset Kayaking'))
      ..add(ActivityFormDateChanged(DateTime(2026, 12, 14)))
      ..add(const ActivityFormTimeChanged(17, 30))
      ..add(const ActivityFormLocationChanged(_loc))
      ..add(const ActivityFormPriceChanged('3,500'));
    await settle();
    return b;
  }

  test('create: the first community and its zone', () async {
    final b = build()..add(const ActivityFormRequested());
    await settle();
    expect(b.state.ready, isTrue);
    expect((b.state.form!.communitySlug, b.state.form!.timezone), ('explore-kenya', 'Africa/Nairobi'));
    expect(b.state.loaded, 1);
    await b.close();
  });

  blocTest<ActivityFormBloc, ActivityFormState>(
    'edit by someone who isn’t the host is not found',
    setUp: () => when(() => host.activity(activityId)).thenAnswer((_) async => PublicActivity.fromJson(activityJson())),
    build: () => build(id: activityId),
    act: (b) => b.add(const ActivityFormRequested()),
    verify: (b) => expect(b.state.error, LoadError.notFound),
  );

  blocTest<ActivityFormBloc, ActivityFormState>(
    'offline load',
    setUp: () => when(() => host.communities()).thenAnswer((_) async => throw const ApiException(message: 'network')),
    build: build,
    act: (b) => b.add(const ActivityFormRequested()),
    verify: (b) => expect(b.state.error, LoadError.offline),
  );

  test('Publish on an empty form shows the errors and sends nothing', () async {
    final b = build()..add(const ActivityFormRequested());
    await settle();
    b.add(const ActivityFormSubmitted());
    await settle();
    expect(b.state.showErrors, isTrue);
    expect(b.state.validation.keys, containsAll([Field.photo, Field.title, Field.date]));
    expect(b.state.scrolls, 1);
    b.add(const ActivityFormTitleChanged('Kayak'));
    await settle();
    expect(b.state.validation.containsKey(Field.title), isFalse);
    verifyNever(() => host.create(any()));
    await b.close();
  });

  test('the photo uploads and fills the key; a failed upload says so', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => host.pickPhoto()).thenAnswer((_) async => bytes);
    when(() => host.uploadPhoto(bytes)).thenAnswer((_) async => (key: 'a/b.jpg', preview: bytes));
    final b = build()..add(const ActivityFormRequested());
    await settle();
    b.add(const ActivityFormPhotoRequested());
    await settle();
    expect((b.state.form!.photoKey, b.state.preview, b.state.photoBusy), ('a/b.jpg', bytes, false));

    when(() => host.uploadPhoto(bytes)).thenThrow(const PhotoError(false));
    b.add(const ActivityFormPhotoRequested());
    await settle();
    expect(b.state.errors[Field.photo], photoUploadFailed);
    expect(b.state.photoBusy, isFalse);
    await b.close();
  });

  test('Publish creates once, however often it is tapped', () async {
    final gate = Completer<String>();
    when(() => host.create(any())).thenAnswer((_) => gate.future);
    when(() => host.pickPhoto()).thenAnswer((_) async => Uint8List(1));
    when(() => host.uploadPhoto(any())).thenAnswer((_) async => (key: 'a/b.jpg', preview: Uint8List(1)));
    final b = await filled();
    b.add(const ActivityFormPhotoRequested());
    await settle();
    b
      ..add(const ActivityFormSubmitted())
      ..add(const ActivityFormSubmitted());
    await settle();
    expect(b.state.saving, isTrue);
    gate.complete(activityId);
    await settle();
    expect(b.state.publishedId, activityId);
    verify(() => host.create(any())).called(1);
    await b.close();
  });

  test('Save sends only the changed fields, then "Changes saved"', () async {
    when(() => host.activity(activityId)).thenAnswer((_) async => unbooked);
    when(() => host.patch(any(), any())).thenAnswer((_) async {});
    final b = build(id: activityId)..add(const ActivityFormRequested());
    await settle();
    b.add(const ActivityFormTitleChanged('Sunrise Kayaking'));
    await settle();
    b.add(const ActivityFormSubmitted());
    await settle();
    verify(() => host.patch(activityId, {'title': 'Sunrise Kayaking'})).called(1);
    expect((b.state.saves, b.state.saving), (1, false));
    expect(b.state.baseline!.title, 'Sunrise Kayaking');
    await b.close();
  });

  test('location_locked lands on date and place, refreshes the snapshot, and an edit clears it', () async {
    when(() => host.activity(activityId)).thenAnswer((_) async => unbooked);
    when(() => host.patch(any(), any())).thenThrow(const ApiException(status: 409, code: 'location_locked'));
    final b = build(id: activityId)..add(const ActivityFormRequested());
    await settle();
    when(() => host.activity(activityId)).thenAnswer((_) async => hosted);
    b.add(const ActivityFormTimeChanged(18, 0));
    await settle();
    b.add(const ActivityFormSubmitted());
    await settle();
    expect(b.state.apiErrors.keys, containsAll([Field.date, Field.location]));
    expect(b.state.locked, isTrue);
    expect(b.state.scrolls, 1);
    b.add(const ActivityFormLocationChanged(_loc));
    await settle();
    expect(b.state.apiErrors, isEmpty);
    await b.close();
  });

  test('capacity_below_bookings lands on spots; other failures on the banner', () async {
    when(() => host.activity(activityId)).thenAnswer((_) async => hosted);
    when(() => host.patch(any(), any())).thenThrow(const ApiException(status: 409, code: 'capacity_below_bookings'));
    final b = build(id: activityId)..add(const ActivityFormRequested());
    await settle();
    b.add(const ActivityFormCapacityChanged(20));
    await settle();
    b.add(const ActivityFormSubmitted());
    await settle();
    expect(b.state.apiErrors[Field.capacity], 'That’s fewer spots than people have booked.');

    when(() => host.patch(any(), any())).thenThrow(const ApiException(message: 'network'));
    b.add(const ActivityFormSubmitted());
    await settle();
    expect(b.state.banner, 'Check your connection and try again.');
    await b.close();
  });

  test('a new community brings its zone unless the host picked one', () async {
    final b = build()..add(const ActivityFormRequested());
    await settle();
    b.add(const ActivityFormCommunityChanged('the-medina-collective'));
    await settle();
    expect(b.state.form!.timezone, 'Africa/Casablanca');
    b
      ..add(const ActivityFormTimezoneChanged('Europe/London'))
      ..add(const ActivityFormCommunityChanged('explore-kenya'));
    await settle();
    expect(b.state.form!.timezone, 'Europe/London');
    await b.close();
  });
}
