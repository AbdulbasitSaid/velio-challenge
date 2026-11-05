// B1's content: photo with live spots, details, who's going, the action, About, where, and the host.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/activity_display.dart';
import '../../ui/cards.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';
import '../bloc/activity_bloc.dart';
import 'activity_action.dart';

class ActivityContent extends StatelessWidget {
  const ActivityContent({super.key, required this.state, required this.online});
  final ActivityState state;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final a = state.activity!;
    final spotsState = !online || state.reconnecting
        ? SpotsState.stale
        : (state.live?.changed ?? false)
        ? SpotsState.changed
        : SpotsState.live;
    final members = state.members ?? a.members;
    final priceNote = a.priceMinor == 0
        ? 'Free. Velio doesn’t take payment.'
        : '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day. Velio doesn’t take payment.';

    return ScreenBody(
      children: [
        HeroPhoto(
          url: a.photoUrl,
          dimmed: state.soldOut || state.started,
          badge: SpotsBadge(spots: state.spots, state: spotsState),
        ),
        Semantics(
          header: true,
          child: Text(a.title, style: VelioText.display.copyWith(fontSize: 34, height: 38 / 34)),
        ),
        DetailRows([
          DetailRow('calendar', formatWhen(a.startsAt, a.timezone), zoneLabel(a.timezone)),
          DetailRow('pin', a.location.venueName, a.location.addressText),
          DetailRow(
            'price',
            a.priceMinor == 0 ? 'Free' : '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day',
          ),
          DetailRow('people', '${a.capacity} spots in total'),
        ]),
        AvatarStack(people: going(members), total: members.count),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActivityAction(state: state, online: online),
            const SizedBox(height: VelioSpace.s3),
            Text(
              priceNote,
              textAlign: TextAlign.center,
              style: VelioText.caption.copyWith(color: VelioColors.muted),
            ),
          ],
        ),
        const Divider(height: 1, thickness: 1, color: VelioColors.line),
        if (a.description.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading('About'),
              const SizedBox(height: VelioSpace.s2),
              Text(a.description, style: VelioText.body),
            ],
          ),
        LocationBlock(place: placeOf(a.location), offline: !online),
        HostCard(
          name: a.host.shortName,
          seed: a.host.avatarSeed,
          community: a.community.name,
          onProfile: () => context.push('/users/${a.host.id}'),
        ),
      ],
    );
  }
}
