// H2 create and edit (S7b FR-007, FR-008), ported from apps/web/lib/host-form.ts: the form's state, its
// copy-deck validation and the request bodies. Free of widgets so the rules are unit-tested alone.
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:velio_api/velio_api.dart';

import 'api.dart';
import 'format.dart';

const meetingPointMax = 140;
const capacityMax = 100000;
const lockedNote = 'Date, time and place are locked now that people have booked.';

class PickedLocation {
  const PickedLocation({
    required this.placeId,
    required this.venueName,
    required this.addressText,
    required this.lat,
    required this.lng,
  });
  final String? placeId;
  final String venueName;
  final String addressText;
  final double lat;
  final double lng;

  PickedLocation copyWith({String? venueName, String? addressText, double? lat, double? lng, bool keepPlace = true}) =>
      PickedLocation(
        placeId: keepPlace ? placeId : null,
        venueName: venueName ?? this.venueName,
        addressText: addressText ?? this.addressText,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );

  @override
  bool operator ==(Object other) =>
      other is PickedLocation &&
      other.placeId == placeId &&
      other.venueName == venueName &&
      other.addressText == addressText &&
      other.lat == lat &&
      other.lng == lng;

  @override
  int get hashCode => Object.hash(placeId, venueName, addressText, lat, lng);
}

class HostForm {
  const HostForm({
    required this.communitySlug,
    this.title = '',
    this.description = '',
    this.date = '',
    this.time = '',
    required this.timezone,
    this.location,
    this.meetingPoint = '',
    this.price = '',
    this.capacity = 10,
    this.photoKey,
  });
  final String communitySlug;
  final String title;
  final String description;

  /// `YYYY-MM-DD` and `HH:mm`, wall-clock time in [timezone].
  final String date;
  final String time;
  final String timezone;
  final PickedLocation? location;
  final String meetingPoint;

  /// As typed, in major units of the community's currency.
  final String price;

  /// Null while the field is empty.
  final int? capacity;
  final String? photoKey;

  HostForm copyWith({
    String? communitySlug,
    String? title,
    String? description,
    String? date,
    String? time,
    String? timezone,
    PickedLocation? Function()? location,
    String? meetingPoint,
    String? price,
    int? Function()? capacity,
    String? Function()? photoKey,
  }) => HostForm(
    communitySlug: communitySlug ?? this.communitySlug,
    title: title ?? this.title,
    description: description ?? this.description,
    date: date ?? this.date,
    time: time ?? this.time,
    timezone: timezone ?? this.timezone,
    location: location == null ? this.location : location(),
    meetingPoint: meetingPoint ?? this.meetingPoint,
    price: price ?? this.price,
    capacity: capacity == null ? this.capacity : capacity(),
    photoKey: photoKey == null ? this.photoKey : photoKey(),
  );
}

enum Field { photo, title, date, time, timezone, location, venueName, addressText, price, capacity }

typedef FormErrors = Map<Field, String>;

/// Communities carry no currency, so each one prices in its country's (PRD Q11). The time zone is
/// the default for a new activity (S7b PLANNING §12 D3). Unknown communities fall back to the first.
const _communities = {
  'explore-kenya': (currency: 'KES', lat: -1.2921, lng: 36.8219, zone: 'Africa/Nairobi'),
  'the-tanzania-experience': (currency: 'TZS', lat: -3.3869, lng: 36.683, zone: 'Africa/Dar_es_Salaam'),
  'the-medina-collective': (currency: 'MAD', lat: 31.6295, lng: -7.9811, zone: 'Africa/Casablanca'),
};

({String currency, double lat, double lng, String zone}) _community(String slug) =>
    _communities[slug] ?? _communities['explore-kenya']!;

String communityCurrency(String slug) => _community(slug).currency;
({double lat, double lng}) communityCenter(String slug) => (lat: _community(slug).lat, lng: _community(slug).lng);
String communityZone(String slug) => _community(slug).zone;

bool isTimeZone(String zone) {
  if (zone.trim().isEmpty) return false;
  try {
    tz.getLocation(zone);
    return true;
  } on tz.LocationNotFoundException {
    return false;
  }
}

/// The zones a host can pick, as IANA names ("Africa/Nairobi").
List<String> timeZoneNames() =>
    tz.timeZoneDatabase.locations.keys.where((z) => z.contains('/') && !z.startsWith('Etc/')).toList()..sort();

final _dateRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _timeRe = RegExp(r'^(\d{2}):(\d{2})$');

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-12-05T17:30:00+03:00` for 17:30 on 5 December in [zone]; null when any part is missing.
String? zonedToIso(String date, String time, String zone) {
  final d = _dateRe.firstMatch(date);
  final t = _timeRe.firstMatch(time);
  if (d == null || t == null || !isTimeZone(zone)) return null;
  final at = tz.TZDateTime(
    tz.getLocation(zone),
    int.parse(d[1]!),
    int.parse(d[2]!),
    int.parse(d[3]!),
    int.parse(t[1]!),
    int.parse(t[2]!),
  );
  final offset = at.timeZoneOffset.inMinutes;
  final sign = offset < 0 ? '-' : '+';
  final abs = offset.abs();
  return '${date}T$time:00$sign${_two(abs ~/ 60)}:${_two(abs % 60)}';
}

/// The inverse, for the edit form: the date and time fields' values in the activity's zone.
({String date, String time}) isoToZoned(DateTime instant, String zone) {
  final local = tz.TZDateTime.from(instant, tz.getLocation(zone));
  return (
    date: '${local.year.toString().padLeft(4, '0')}-${_two(local.month)}-${_two(local.day)}',
    time: '${_two(local.hour)}:${_two(local.minute)}',
  );
}

/// "3,500" → 350000 for KES; null when it isn't a positive amount the currency can hold.
int? parsePrice(String raw, String currency) {
  final text = raw.replaceAll(RegExp(r'[\s,]'), '');
  final digits = currencyDigits(currency);
  final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(text);
  if (m == null || (m[2] != null && m[2]!.length > digits)) return null;
  final whole = BigInt.parse(m[1]!) * BigInt.from(10).pow(digits);
  final fraction = (m[2] ?? '').padRight(digits, '0');
  final minor = whole + (fraction.isEmpty ? BigInt.zero : BigInt.parse(fraction));
  // JavaScript's safe-integer ceiling, as the web checks.
  return minor > BigInt.zero && minor <= BigInt.from(9007199254740991) ? minor.toInt() : null;
}

/// The edit form's price field, from minor units.
String priceText(int minor, String currency) {
  final digits = currencyDigits(currency);
  final f = NumberFormat.decimalPattern('en')
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = digits;
  return f.format(minor / _pow10(digits));
}

int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

/// Copy deck `host.spotsHelp`.
String spotsHelp(int booked) => booked > 0
    ? '$booked booked, so at least $booked. You can always add more.'
    : 'You can add spots later, never fewer than people booked.';

/// Copy deck `host.validationSummary`.
String summaryTitle(int count, {required bool editing}) {
  final things = count == 1 ? '1 thing needs' : '$count things need';
  return '$things fixing before you can ${editing ? 'save' : 'publish'}.';
}

/// Copy-deck errors (UI design §5.5 batch 3), in the form's order. Date, time, zone and location are
/// locked after the first booking and aren't checked then.
FormErrors validate(
  HostForm form, {
  required bool editing,
  required bool locked,
  required int booked,
  required String currency,
  required DateTime now,
}) {
  final e = <Field, String>{};
  if (form.photoKey == null) e[Field.photo] = 'Add a photo. It shows on the activity page and every invite.';
  if (form.title.trim().isEmpty) e[Field.title] = 'Add a title.';
  if (!locked) {
    final iso = zonedToIso(form.date, form.time, form.timezone);
    if (form.date.isEmpty || (iso != null && !DateTime.parse(iso).isAfter(now))) {
      e[Field.date] = 'Pick a date in the future.';
    }
    if (form.time.isEmpty) e[Field.time] = 'Pick a start time.';
    if (!isTimeZone(form.timezone)) e[Field.timezone] = 'Pick a time zone from the list.';
    final loc = form.location;
    if (loc == null || !loc.lat.isFinite || !loc.lng.isFinite) {
      e[Field.location] = 'Search for a place, or drop a pin on the map.';
    } else {
      if (loc.venueName.trim().isEmpty) e[Field.venueName] = 'Add the venue name.';
      if (loc.addressText.trim().isEmpty) e[Field.addressText] = 'Add the address.';
    }
  }
  if (!editing && parsePrice(form.price, currency) == null) e[Field.price] = 'Enter the price per person.';
  final floor = booked > 1 ? booked : 1;
  final capacity = form.capacity;
  if (capacity == null || capacity < floor) {
    e[Field.capacity] = booked > 0 ? '$booked booked, so at least $booked.' : 'At least 1 spot.';
  } else if (capacity > capacityMax) {
    e[Field.capacity] = 'At most ${NumberFormat.decimalPattern('en').format(capacityMax)} spots.';
  }
  return e;
}

Map<String, Object?> _locationBody(HostForm form) {
  final loc = form.location!;
  final meeting = form.meetingPoint.trim();
  return {
    'placeId': loc.placeId,
    'venueName': loc.venueName.trim(),
    'addressText': loc.addressText.trim(),
    'lat': loc.lat,
    'lng': loc.lng,
    'meetingPoint': meeting.isEmpty ? null : meeting,
  };
}

/// Only call after [validate] returns no errors.
Map<String, Object?> createBody(HostForm form) {
  final currency = communityCurrency(form.communitySlug);
  return {
    'communitySlug': form.communitySlug,
    'title': form.title.trim(),
    'description': form.description.trim(),
    'startsAt': zonedToIso(form.date, form.time, form.timezone),
    'timezone': form.timezone,
    'location': _locationBody(form),
    'priceMinor': parsePrice(form.price, currency),
    'currency': currency,
    'capacity': form.capacity,
    if (form.photoKey != null) 'photoKey': form.photoKey,
  };
}

bool _sameLocation(Map<String, Object?> a, Map<String, Object?> b) => a.entries.every((e) => b[e.key] == e.value);

/// The changed fields only; never the locked ones, which the API would refuse (`location_locked`).
Map<String, Object?> patchBody(HostForm form, HostForm initial, {required bool locked}) {
  final patch = <String, Object?>{};
  if (form.title.trim() != initial.title) patch['title'] = form.title.trim();
  if (form.description.trim() != initial.description) patch['description'] = form.description.trim();
  if (form.capacity != initial.capacity) patch['capacity'] = form.capacity;
  if (form.photoKey != initial.photoKey) patch['photoKey'] = form.photoKey;
  if (!locked) {
    final startsAt = zonedToIso(form.date, form.time, form.timezone);
    if (startsAt != zonedToIso(initial.date, initial.time, initial.timezone)) patch['startsAt'] = startsAt;
    if (form.timezone != initial.timezone) patch['timezone'] = form.timezone;
    final location = _locationBody(form);
    if (initial.location == null || !_sameLocation(location, _locationBody(initial))) patch['location'] = location;
  }
  return patch;
}

/// `/photos/<key>` → `<key>`.
String? photoKeyFromUrl(String? url) =>
    url != null && url.startsWith('/photos/') ? url.substring('/photos/'.length) : null;

/// The edit form's starting values, from the public snapshot.
HostForm formFromActivity(PublicActivity a) {
  final when = isoToZoned(a.startsAt, a.timezone);
  return HostForm(
    communitySlug: a.community.slug,
    title: a.title,
    description: a.description,
    date: when.date,
    time: when.time,
    timezone: a.timezone,
    location: PickedLocation(
      placeId: a.location.placeId,
      venueName: a.location.venueName,
      addressText: a.location.addressText,
      lat: a.location.lat.toDouble(),
      lng: a.location.lng.toDouble(),
    ),
    meetingPoint: a.location.meetingPoint ?? '',
    price: priceText(a.priceMinor, a.currency),
    capacity: a.capacity,
    photoKey: photoKeyFromUrl(a.photoUrl),
  );
}

/// "Amara O.", as the API shows a person publicly (PRD Q12).
String shortName(String displayName) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return parts.first;
  return '${parts.first} ${String.fromCharCode(parts.last.runes.first).toUpperCase()}.';
}

/// A save error on its fields (with a refresh of the snapshot), or as the banner's text.
sealed class SaveFailure {
  const SaveFailure();
}

class FieldFailure extends SaveFailure {
  const FieldFailure(this.fields, {this.refresh = false});
  final FormErrors fields;
  final bool refresh;
}

class BannerFailure extends SaveFailure {
  const BannerFailure(this.text);
  final String text;
}

SaveFailure saveFailure(Object err) {
  final e = ApiException.from(err);
  if (e.code == 'location_locked') {
    return const FieldFailure({Field.date: lockedNote, Field.location: lockedNote}, refresh: true);
  }
  if (e.code == 'capacity_below_bookings') {
    return const FieldFailure({Field.capacity: 'That’s fewer spots than people have booked.'}, refresh: true);
  }
  if (e.code == 'validation_failed' && e.message.contains('photoKey')) {
    return const FieldFailure({Field.photo: 'Upload the photo again.'});
  }
  if (e.code == 'forbidden' || e.code == 'not_found') return const BannerFailure('You can’t edit this activity.');
  return const BannerFailure('Check your connection and try again.');
}
