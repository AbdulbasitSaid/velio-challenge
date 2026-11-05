// S7b unit checks: V-FORM-1 (host form rules), V-BOOK-1 (booking outcomes), V-ROW-1 (host rows),
// V-ATT-1 (attendance rules), V-PHOTO-1 (crop, encode, bucket headers). Expected values match the
// web's tests for the same modules (apps/web/test).
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:velio/data/api.dart';
import 'package:velio/data/identity.dart';
import 'package:velio/data/photo.dart';
import 'package:velio/domain/attendance.dart';
import 'package:velio/domain/booking.dart';
import 'package:velio/domain/host_form.dart';
import 'package:velio/domain/role.dart';
import 'package:velio/host_list/host_list.dart';
import 'package:velio/repositories/preferences_repository.dart';
import 'package:velio/ui/components.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';

const _loc = PickedLocation(
  placeId: 'p1',
  venueName: 'Boat Club',
  addressText: 'Moi South Lake Rd',
  lat: -0.77,
  lng: 36.43,
);

HostForm _valid() => const HostForm(
  communitySlug: 'explore-kenya',
  title: 'Sunset Kayaking',
  date: '2026-12-14',
  time: '17:30',
  timezone: 'Africa/Nairobi',
  location: _loc,
  price: '3,500',
  capacity: 14,
  photoKey: 'a/b.jpg',
);

FormErrors _check(HostForm f, {bool editing = false, bool locked = false, int booked = 0}) =>
    validate(f, editing: editing, locked: locked, booked: booked, currency: 'KES', now: DateTime.utc(2026, 11, 4, 12));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('host form (V-FORM-1)', () {
    test('zoned times: fixed offset, DST, and back', () {
      expect(zonedToIso('2026-12-05', '17:30', 'Africa/Nairobi'), '2026-12-05T17:30:00+03:00');
      expect(zonedToIso('2026-07-01', '09:00', 'Europe/London'), '2026-07-01T09:00:00+01:00');
      expect(zonedToIso('2026-01-01', '09:00', 'Europe/London'), '2026-01-01T09:00:00+00:00');
      expect(zonedToIso('2026-12-05', '', 'Africa/Nairobi'), isNull);
      expect(zonedToIso('2026-12-05', '17:30', 'Mars/Olympus'), isNull);
      final back = isoToZoned(DateTime.parse('2026-12-05T14:30:00Z'), 'Africa/Nairobi');
      expect((back.date, back.time), ('2026-12-05', '17:30'));
    });

    test('prices in minor units', () {
      expect(parsePrice('3,500', 'KES'), 350000);
      expect(parsePrice('12.5', 'KES'), 1250);
      expect(parsePrice('12.555', 'KES'), isNull);
      expect(parsePrice('0', 'KES'), isNull);
      expect(parsePrice('abc', 'KES'), isNull);
      expect(parsePrice('500', 'JPY'), 500);
      expect(priceText(350000, 'KES'), '3,500');
      expect(priceText(1250, 'KES'), '12.5');
    });

    test('a complete form has no errors; an empty one has the copy deck’s, in order', () {
      expect(_check(_valid()), isEmpty);
      final e = _check(const HostForm(communitySlug: 'explore-kenya', timezone: 'Nope', capacity: 0));
      expect(e.keys.toList(), [
        Field.photo,
        Field.title,
        Field.date,
        Field.time,
        Field.timezone,
        Field.location,
        Field.price,
        Field.capacity,
      ]);
      expect(e[Field.location], 'Search for a place, or drop a pin on the map.');
      expect(summaryTitle(e.length, editing: false), '8 things need fixing before you can publish.');
      expect(summaryTitle(1, editing: true), '1 thing needs fixing before you can save.');
    });

    test('past dates, missing venue, half-typed pin, capacity floor and ceiling', () {
      expect(_check(_valid().copyWith(date: '2026-11-01'))[Field.date], 'Pick a date in the future.');
      final noVenue = _valid().copyWith(location: () => _loc.copyWith(venueName: ' '));
      expect(_check(noVenue)[Field.venueName], 'Add the venue name.');
      final halfPin = _valid().copyWith(location: () => _loc.copyWith(lat: double.nan));
      expect(_check(halfPin)[Field.location], isNotNull);
      expect(_check(_valid().copyWith(capacity: () => 3), booked: 5)[Field.capacity], '5 booked, so at least 5.');
      expect(_check(_valid().copyWith(capacity: () => 100001))[Field.capacity], 'At most 100,000 spots.');
    });

    test('locked and editing skip date, place and price', () {
      final f = _valid().copyWith(date: '', location: () => null, price: '');
      expect(_check(f, editing: true, locked: true, booked: 2), isEmpty);
    });

    test('create body', () {
      final b = createBody(_valid().copyWith(meetingPoint: '  '));
      expect(b['startsAt'], '2026-12-14T17:30:00+03:00');
      expect(b['priceMinor'], 350000);
      expect(b['currency'], 'KES');
      expect((b['location'] as Map)['meetingPoint'], isNull);
      expect(b['photoKey'], 'a/b.jpg');
    });

    test('patch body: changed fields only, never the locked ones', () {
      final initial = _valid();
      expect(patchBody(initial, initial, locked: false), isEmpty);
      final changed = initial.copyWith(title: 'Sunrise Kayaking', capacity: () => 20, time: '18:00');
      expect(patchBody(changed, initial, locked: false), {
        'title': 'Sunrise Kayaking',
        'capacity': 20,
        'startsAt': '2026-12-14T18:00:00+03:00',
      });
      expect(patchBody(changed, initial, locked: true), {'title': 'Sunrise Kayaking', 'capacity': 20});
    });

    test('community defaults, photo keys and short names', () {
      expect(communityCurrency('the-medina-collective'), 'MAD');
      expect(communityZone('the-tanzania-experience'), 'Africa/Dar_es_Salaam');
      expect(communityCurrency('unknown'), 'KES');
      expect(photoKeyFromUrl('/photos/u/k.jpg'), 'u/k.jpg');
      expect(photoKeyFromUrl(null), isNull);
      expect(shortName('Amara Okafor'), 'Amara O.');
      expect(shortName('Amara'), 'Amara');
      expect(spotsHelp(3), '3 booked, so at least 3. You can always add more.');
    });

    test('save failures land on fields or the banner', () {
      final locked = saveFailure(const ApiException(status: 409, code: 'location_locked')) as FieldFailure;
      expect(locked.fields.keys, containsAll([Field.date, Field.location]));
      expect(locked.refresh, isTrue);
      final cap = saveFailure(const ApiException(status: 409, code: 'capacity_below_bookings')) as FieldFailure;
      expect(cap.fields[Field.capacity], 'That’s fewer spots than people have booked.');
      expect(
        (saveFailure(const ApiException(status: 403, code: 'forbidden')) as BannerFailure).text,
        'You can’t edit this activity.',
      );
      expect(
        (saveFailure(const ApiException(message: 'network')) as BannerFailure).text,
        'Check your connection and try again.',
      );
    });

    test('form from the snapshot round-trips', () {
      final f = formFromActivity(PublicActivity.fromJson(activityJson()));
      expect((f.date, f.time, f.timezone), ('2026-12-14', '17:30', 'Africa/Nairobi'));
      expect(f.price, '3,500');
      expect(f.meetingPoint, 'Meet at the blue gate by the jetty, 15 minutes before');
      expect(patchBody(f, f, locked: false), isEmpty);
    });
  });

  test('booking outcomes (V-BOOK-1)', () {
    BookingOutcome of(String? code, [int? status = 409]) => bookingOutcome(ApiException(status: status, code: code));
    expect(of('sold_out'), BookingOutcome.soldOut);
    expect(of('activity_started'), BookingOutcome.started);
    expect(of('bookings_paused'), BookingOutcome.paused);
    expect(of('already_booked'), BookingOutcome.refresh);
    expect(of('booking_removed'), BookingOutcome.refresh);
    expect(of('forbidden', 403), BookingOutcome.refresh);
    expect(of('unauthenticated', 401), BookingOutcome.signIn);
    expect(of('internal', 500), BookingOutcome.error);
    expect(bookingOutcome(const ApiException(message: 'network')), BookingOutcome.error);
  });

  test('host rows (V-ROW-1)', () {
    HostActivityItem item({int booked = 8, int marked = 0, int attended = 0, int spotsLeft = 6}) =>
        HostActivityItem.fromJson(
          hostItemJson(booked: booked, marked: marked, attended: attended, spotsLeft: spotsLeft),
        );
    expect(hostRow(item(booked: 0), past: false), (status: 'No bookings yet', tone: ChipTone.neutral));
    expect(hostRow(item(), past: false), (status: '6 spots left', tone: ChipTone.lime));
    expect(hostRow(item(spotsLeft: 0), past: false), (status: 'Sold out', tone: ChipTone.forest));
    expect(hostRow(item(booked: 0), past: true), (status: 'No bookings', tone: ChipTone.neutral));
    expect(hostRow(item(), past: true), (status: 'Mark attendance', tone: ChipTone.danger));
    expect(hostRow(item(marked: 6, attended: 5), past: true), (status: '5 attended', tone: ChipTone.neutral));
  });

  group('attendance (V-ATT-1)', () {
    final data = Attendance.fromJson(attendanceJson());
    final a1 = data.attendees[0], a2 = data.attendees[1], a3 = data.attendees[2];

    test('sources', () {
      expect(attendeeSource(a1), 'Direct');
      expect(attendeeSource(a2), 'Via Tunde');
      expect(attendeeSource(a3), 'Public link');
    });

    test('search by name or ref, with or without VLO-', () {
      expect(matchesGuest(a1, ''), isTrue);
      expect(matchesGuest(a1, 'guest1'), isTrue);
      expect(matchesGuest(a1, 'vlo-10001'), isTrue);
      expect(matchesGuest(a1, '10001'), isTrue);
      expect(matchesGuest(a1, '10002'), isFalse);
      // One character only matches names: refs need two.
      expect(matchesGuest(a2, '1'), isFalse);
    });

    test('order: newest first before the start, booking order after, removed last', () {
      expect(orderAttendees(data.attendees, started: false).map((a) => a.ref), ['VLO-10002', 'VLO-10001', 'VLO-10003']);
      expect(orderAttendees(data.attendees, started: true).map((a) => a.ref), ['VLO-10001', 'VLO-10002', 'VLO-10003']);
    });

    test('stats count confirmed bookings only', () {
      final s = attendanceStats(
        Attendance.fromJson({
          ...attendanceJson(),
          'attendees': [
            attendeeJson('1', mark: 'attended'),
            attendeeJson('2', source: 'vouch', mark: 'no_show'),
            attendeeJson('3', status: 'removed', mark: 'attended'),
          ],
        }),
      );
      expect((s.booked, s.capacity, s.throughInvites, s.marked, s.attended, s.noShows), (2, 14, 1, 2, 1, 1));
    });

    test('mark failures', () {
      expect(
        markFailure(const ApiException(status: 409, code: 'booking_removed'), 'Guest1 Gathoni'),
        'Guest1 was removed, so they can’t be marked.',
      );
      expect(markFailure(const ApiException(message: 'network'), 'X'), 'You’re offline. Reconnect to mark attendance.');
      expect(
        markFailure(const ApiException(status: 500, code: 'internal'), 'X'),
        'We couldn’t save that mark. Try again.',
      );
    });
  });

  group('photo (V-PHOTO-1)', () {
    test('centre 16:10 crop', () {
      expect(cropTo16x10(2000, 1000), (x: 200, y: 0, w: 1600, h: 1000));
      expect(cropTo16x10(1000, 1000), (x: 0, y: 188, w: 1000, h: 625));
      expect(cropTo16x10(1600, 1000), (x: 0, y: 0, w: 1600, h: 1000));
    });

    test('encodes 1280 and 640 px JPEGs at 16:10', () {
      final png = img.encodePng(img.Image(width: 3000, height: 2000));
      final out = encodePhoto(png)!;
      final large = img.decodeJpg(out.large)!, small = img.decodeJpg(out.small)!;
      expect((large.width, large.height), (1280, 800));
      expect((small.width, small.height), (640, 400));
      expect(encodePhoto(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('the bucket upload sends none of our headers (SEC-001)', () {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final uploader = PhotoUploader(Api(Dio(), Identity(MemorySecretStore(), SharedPreferencesAsync())));
      expect(uploader.bucket.interceptors.whereType<VelioInterceptor>(), isEmpty);
    });
  });

  test('role is remembered (V-NAV-1)', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = PreferencesRepository(SharedPreferencesAsync());
    expect(await prefs.loadRole(), Role.booker);
    await prefs.saveRole(Role.host);
    expect(await prefs.loadRole(), Role.host);
  });
}
