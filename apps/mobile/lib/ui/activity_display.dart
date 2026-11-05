// How activity models read on screen, shared by the invite, Plan, activity and profile screens.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';

import '../domain/format.dart';
import 'components.dart';
import 'location.dart';

Place placeOf(PublicLocation l) => Place(
  venue: l.venueName,
  address: l.addressText,
  lat: l.lat.toDouble(),
  lng: l.lng.toDouble(),
  directionsUrl: l.directionsUrl,
  meetingPoint: l.meetingPoint,
);

List<DetailRow> activityRows(PublicActivity a) => [
  DetailRow('calendar', formatWhen(a.startsAt, a.timezone), zoneLabel(a.timezone)),
  DetailRow('price', '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day'),
  DetailRow('host', 'Hosted by ${a.host.shortName}'),
];

List<StackPerson> going(PublicActivityMembers m) => [for (final p in m.preview) StackPerson(p.shortName, p.avatarSeed)];

/// Opens the activity page in the app (S7b FR-013).
NextStep cardStep(BuildContext context, ActivityCard c) => NextStep(
  title: c.title,
  meta: '${formatWhen(c.startsAt, c.timezone)} · ${spotsLabel(c.spotsLeft)}',
  photoUrl: c.photoUrl,
  onTap: () => context.push('/activities/${c.id}'),
);
