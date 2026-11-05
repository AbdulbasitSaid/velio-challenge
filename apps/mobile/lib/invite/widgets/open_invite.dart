import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../domain/format.dart';
import '../../domain/invite_logic.dart';
import '../../ui/activity_display.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';
import 'claim_action.dart';

/// G1 (vouch) or G2 (public), with live spots and the claim action.
class OpenInvite extends StatelessWidget {
  const OpenInvite({
    super.key,
    required this.view,
    required this.spots,
    required this.spotsState,
    required this.block,
    required this.online,
    required this.cachedAt,
  });
  final InviteView view;
  final int spots;
  final SpotsState spotsState;
  final OpenBlock block;
  final bool online;
  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final a = view.activity;
    final vouch = view.rail == InviteViewRailEnum.vouch;
    final inviter = view.inviter;
    return ScreenBody(
      children: [
        if (!online)
          VBanner(
            tone: BannerTone.offline,
            title: cachedAt == null
                ? 'You’re offline'
                : 'You’re offline · ${updatedAgo(cachedAt!, context.read<AppConfig>().clock())}',
            body: 'Showing the saved invite. Reconnect to claim.',
          ),
        if (vouch)
          Row(
            children: [
              Avatar(name: inviter.shortName, seed: inviter.avatarSeed, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: firstName(inviter.shortName),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' wants you on'),
                    ],
                  ),
                  style: VelioText.body.copyWith(fontSize: 17, height: 24 / 17, color: VelioColors.forest),
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VChip(a.community.name, tone: ChipTone.outline, icon: 'people'),
              const SizedBox(height: 10),
              Text(
                'Join the group going to',
                style: VelioText.body.copyWith(fontSize: 17, height: 24 / 17, color: VelioColors.forest),
              ),
            ],
          ),
        HeroPhoto(
          url: a.photoUrl,
          badge: SpotsBadge(spots: spots, state: spotsState),
        ),
        Semantics(
          header: true,
          child: Text(a.title, style: VelioText.display.copyWith(fontSize: 34, height: 38 / 34)),
        ),
        if (view.note != null && view.note!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(VelioSpace.s4),
            decoration: BoxDecoration(
              color: VelioColors.surface,
              borderRadius: BorderRadius.circular(VelioRadius.card),
            ),
            child: Text('“${view.note}” · ${firstName(inviter.shortName)}', style: VelioText.body),
          ),
        DetailRows(activityRows(a)),
        AvatarStack(people: going(a.members), total: a.members.count),
        ClaimAction(view: view, block: block, online: online),
        LocationBlock(place: placeOf(a.location), offline: !online),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('About'),
            const SizedBox(height: VelioSpace.s2),
            Text(a.description, style: VelioText.body),
          ],
        ),
      ],
    );
  }
}
