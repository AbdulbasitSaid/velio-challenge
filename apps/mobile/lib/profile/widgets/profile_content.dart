// P1's content: who they are, member since, and what they host.
import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/activity_display.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final first = firstName(p.person.shortName);
    return ScreenBody(
      gap: VelioSpace.s6,
      children: [
        Column(
          children: [
            Avatar(name: p.person.shortName, seed: p.person.avatarSeed, size: 88),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: Text(p.person.shortName, style: VelioText.title, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 4),
            Text(
              'On Velio since ${monthYear(p.memberSince)}',
              style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
            ),
          ],
        ),
        if (p.hosting.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading('Upcoming with $first'),
              const SizedBox(height: 14),
              NextStepList([for (final c in p.hosting) cardStep(context, c)]),
            ],
          )
        else
          Text(
            '$first isn’t hosting anything right now.',
            textAlign: TextAlign.center,
            style: VelioText.body.copyWith(color: VelioColors.muted),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VIcon('lock', size: 16),
            const SizedBox(width: VelioSpace.s2),
            Expanded(
              child: Text(
                'Profiles never show which activities someone has booked.',
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
