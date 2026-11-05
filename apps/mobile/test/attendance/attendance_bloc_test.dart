// AttendanceBloc (V-BLOC-1): load and its failures, live spots and attendance hints, the start-time
// flip, optimistic marks reverted on failure, removal, and search (REQUIREMENTS §7).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/attendance/attendance.dart';
import 'package:velio/domain/api_exception.dart';
import 'package:velio/domain/load_error.dart';
import 'package:velio/repositories/host_repository.dart';
import 'package:velio/repositories/live_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class MockHostRepository extends Mock implements HostRepository {}

class MockLiveRepository extends Mock implements LiveRepository {}

void main() {
  late MockHostRepository host;
  late MockLiveRepository live;
  late StreamController<LiveUpdate> updates;
  final before = Attendance.fromJson(attendanceJson());
  final after = Attendance.fromJson(attendanceJson(started: true));
  final activity = PublicActivity.fromJson(activityJson());
  final now = DateTime.utc(2026, 11, 4, 12, 10);

  setUp(() {
    host = MockHostRepository();
    live = MockLiveRepository();
    updates = StreamController<LiveUpdate>.broadcast();
    when(() => live.status).thenReturn(RealtimeStatus.connecting);
    when(() => live.watch(any())).thenAnswer((_) => updates.stream);
    when(() => host.activity(activityId)).thenAnswer((_) async => activity);
    when(() => host.attendance(activityId)).thenAnswer((_) async => before);
  });
  tearDown(() => updates.close());

  AttendanceBloc build({DateTime? at}) =>
      AttendanceBloc(hostRepository: host, liveRepository: live, activityId: activityId, clock: () => at ?? now);

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  test('loads both, follows activity and host topics', () async {
    final b = build()..add(const AttendanceRequested());
    await settle();
    expect(b.state.ready, isTrue);
    expect(b.state.live!.spotsLeft, before.activity.spotsLeft);
    expect(b.state.started, isFalse);
    verify(() => live.watch(['activity:$activityId', 'host:$activityId'])).called(1);
    await b.close();
  });

  blocTest<AttendanceBloc, AttendanceState>(
    '403 is not found',
    setUp: () => when(() => host.attendance(activityId)).thenThrow(const ApiException(status: 403, code: 'forbidden')),
    build: build,
    act: (b) => b.add(const AttendanceRequested()),
    verify: (b) => expect(b.state.error, LoadError.notFound),
  );

  test('a spots event is gated by version and acknowledged; a booking hint refetches', () async {
    when(() => live.rendered(any(), any())).thenReturn(null);
    final b = build()..add(const AttendanceRequested());
    await settle();
    final v = before.activity.version;
    updates.add(LiveSpotsChanged(activityId, 3, v + 1));
    await settle();
    expect((b.state.live!.spotsLeft, b.state.live!.changed), (3, true));
    updates.add(LiveSpotsChanged(activityId, 9, v));
    await settle();
    expect(b.state.live!.spotsLeft, 3);
    verify(() => live.rendered(activityId, v + 1)).called(1);

    final more = Attendance.fromJson({
      ...attendanceJson(),
      'attendees': [...(attendanceJson()['attendees'] as List), attendeeJson('9')],
    });
    when(() => host.attendance(activityId)).thenAnswer((_) async => more);
    updates.add(LiveAttendanceChanged(activityId));
    await settle();
    expect(b.state.arrived, {more.attendees.last.bookingId});
    await b.close();
  });

  test('the start time flips to marking and fetches once', () async {
    final b = build(at: before.activity.startsAt.subtract(const Duration(milliseconds: 30)))
      ..add(const AttendanceRequested());
    await settle();
    expect(b.state.started, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(b.state.started, isTrue);
    verify(() => host.attendance(activityId)).called(2);
    await b.close();
  });

  test('already started at load: marking without a timer', () async {
    when(() => host.attendance(activityId)).thenAnswer((_) async => after);
    final b = build()..add(const AttendanceRequested());
    await settle();
    expect(b.state.started, isTrue);
    await b.close();
  });

  test('a mark shows at once and is reverted with the failure text', () async {
    when(() => host.attendance(activityId)).thenAnswer((_) async => after);
    final a = after.attendees.first;
    final gate = Completer<Attendee>();
    when(() => host.mark(a.bookingId, AttendanceMark.attended)).thenAnswer((_) => gate.future);
    final b = build()..add(const AttendanceRequested());
    await settle();
    b.add(AttendanceMarkPressed(a, AttendanceMark.attended));
    await settle();
    expect(b.state.data!.attendees.first.mark, AttendanceMark.attended);
    gate.completeError(const ApiException(status: 409, code: 'activity_not_started'));
    await settle();
    expect(b.state.data!.attendees.first.mark, a.mark);
    expect(b.state.flash, 'You can mark attendance once the activity starts.');
    expect(b.state.flashes, 1);
    await b.close();
  });

  test('a mark that saves keeps the API’s row; the same mark again sends nothing', () async {
    when(() => host.attendance(activityId)).thenAnswer((_) async => after);
    final a = after.attendees.first;
    final saved = Attendee.fromJson({...a.toJson(), 'mark': 'no_show'});
    when(() => host.mark(a.bookingId, AttendanceMark.noShow)).thenAnswer((_) async => saved);
    final b = build()..add(const AttendanceRequested());
    await settle();
    b.add(AttendanceMarkPressed(a, AttendanceMark.noShow));
    await settle();
    expect(b.state.data!.attendees.first.mark, AttendanceMark.noShow);
    b.add(AttendanceMarkPressed(saved, AttendanceMark.noShow));
    await settle();
    verify(() => host.mark(a.bookingId, AttendanceMark.noShow)).called(1);
    await b.close();
  });

  test('removal refetches and says so; offline says reconnect', () async {
    final a = before.attendees.first;
    when(() => host.remove(a.bookingId)).thenAnswer((_) async {});
    final b = build()..add(const AttendanceRequested());
    await settle();
    b.add(AttendanceRemoveConfirmed(a));
    await settle();
    expect(b.state.flash, '${a.person.displayName.split(' ').first} removed. Their spot is open again.');
    verify(() => host.attendance(activityId)).called(2);

    when(() => host.remove(a.bookingId)).thenThrow(const ApiException(message: 'network'));
    b.add(AttendanceRemoveConfirmed(a));
    await settle();
    expect(b.state.flash, 'You’re offline. Reconnect to remove a guest.');
    await b.close();
  });

  test('search filters the rows', () async {
    final b = build()..add(const AttendanceRequested());
    await settle();
    b.add(const AttendanceQueryChanged('zz'));
    await settle();
    expect(b.state.rows, isEmpty);
    b.add(const AttendanceQueryChanged(''));
    await settle();
    expect(b.state.rows, hasLength(before.attendees.length));
    await b.close();
  });
}
