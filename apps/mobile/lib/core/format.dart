// Display formatting, the same rules as the web (apps/web/lib/format.ts): times always in the
// activity's zone with the zone named (PRD), money in the currency's minor units.
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Same as contracts' INVITE_CODE_ALPHABET: no 0, 1, I, L or O to mix up.
const codeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
final _code = RegExp('^[$codeAlphabet]{6}\$');

/// Like the API: spaces and hyphens dropped, upper-cased; null when it can't be a code.
String? normaliseCode(String raw) {
  final code = raw.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
  return _code.hasMatch(code) ? code : null;
}

/// Keeps only characters a code can have while the guest types or pastes (G8).
String codeInput(String raw) => raw.toUpperCase().split('').where((c) => codeAlphabet.contains(c)).take(6).join();

tz.TZDateTime _inZone(DateTime instant, String zone) {
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(zone));
  } on tz.LocationNotFoundException {
    return tz.TZDateTime.from(instant, tz.UTC);
  }
}

/// "Sat 14 Dec" in the activity's zone.
String formatDay(DateTime instant, String zone) => DateFormat('EEE d MMM', 'en_GB').format(_inZone(instant, zone));

/// "17:30" in the activity's zone.
String formatTime(DateTime instant, String zone) => DateFormat('HH:mm', 'en_GB').format(_inZone(instant, zone));

/// "Sat 14 Dec, 17:30" in the activity's zone.
String formatWhen(DateTime instant, String zone) => '${formatDay(instant, zone)}, ${formatTime(instant, zone)}';

/// "Nairobi time" from "Africa/Nairobi".
String zoneLabel(String zone) => '${zone.split('/').last.replaceAll('_', ' ')} time';

const _zeroDecimal = {'JPY', 'KRW', 'UGX', 'RWF', 'XOF', 'XAF', 'VND', 'CLP', 'ISK'};

/// "KES 3,500", or "Free".
String formatMoney(int minor, String currency) {
  if (minor == 0) return 'Free';
  final digits = _zeroDecimal.contains(currency) ? 0 : 2;
  final amount = minor / _pow10(digits);
  final whole = amount % 1 == 0;
  final f = NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: whole ? 0 : digits);
  return '$currency ${f.format(amount)}';
}

int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

/// "Tunde" from "Tunde A." or "Tunde Adeyemi".
String firstName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
}

/// "TA" from "Tunde A." (packages/design-tokens/src/avatar.ts).
String initials(String name) {
  final parts = name.replaceAll('.', '').trim().split(RegExp(r'\s+'));
  final first = parts.first.isEmpty ? '?' : parts.first[0];
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

/// "June 2023" from "2023-06".
String monthYear(String yyyyMm) {
  final p = yyyyMm.split('-');
  final d = DateTime.utc(int.tryParse(p.first) ?? 1970, p.length > 1 ? int.tryParse(p[1]) ?? 1 : 1);
  return DateFormat('MMMM y', 'en_GB').format(d);
}

/// "9 spots left" on cards and next steps.
String spotsLabel(int spotsLeft) {
  if (spotsLeft <= 0) return 'Sold out';
  return spotsLeft == 1 ? '1 spot left' : '$spotsLeft spots left';
}

/// The contact as "Claiming as" shows it, never the raw value (PRD Privacy, S7 SEC-002):
/// `+254 712 •••` for phones, `z••••@gmail.com` for emails.
String maskContact(String raw) {
  final c = raw.trim();
  final at = c.indexOf('@');
  if (at > 0) return '${c[0]}••••${c.substring(at)}';
  final d = c.replaceAll(RegExp(r'\D'), '');
  if (d.length < 7) return '•••';
  return '${c.startsWith('+') ? '+' : ''}${d.substring(0, 3)} ${d.substring(3, 6)} •••';
}

/// "Last updated 10 min ago" for cached views (PRD M2).
String updatedAgo(DateTime fetchedAt, DateTime now) {
  final m = now.difference(fetchedAt).inMinutes;
  if (m < 1) return 'Last updated just now';
  if (m < 60) return 'Last updated $m min ago';
  final h = m ~/ 60;
  return 'Last updated $h hour${h == 1 ? '' : 's'} ago';
}

/// Copy deck `vouch.message`.
String vouchMessage(String inviteeName, String title, DateTime startsAt, String zone, String link) =>
    '${firstName(inviteeName)}, I’m going to $title on ${formatDay(startsAt, zone)} and want you there. Claim your spot: $link';
