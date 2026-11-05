import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../domain/invite_logic.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/activity_display.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';

/// G5, G6, G7 and the paused link (UI design F-Outcomes).
class InviteOutcome extends StatelessWidget {
  const InviteOutcome({super.key, required this.view, required this.screen, required this.next});
  final InviteView view;
  final InviteScreen screen;
  final NextSteps? next;

  @override
  Widget build(BuildContext context) {
    final a = view.activity;
    final inviter = firstName(view.inviter.shortName);
    final host = firstName(a.host.shortName);
    final profile = context.select((SessionBloc b) => b.state.profile);
    final (headline, body) = switch (screen) {
      SoldOutScreen() => ('This one filled up before you got here.', null),
      ExpiredScreen()
          when a.status == PublicActivityStatusEnum.started && view.status != InviteViewStatusEnum.expired =>
        (
          'This activity has started.',
          'Bookings closed at ${formatTime(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}. $host has more coming up.',
        ),
      ExpiredScreen() => ('This invite expired when the activity started.', 'Bookings close at the start time.'),
      PausedScreen() => ('This link is paused.', '$inviter can send you a new invite, or pick another date below.'),
      ClaimedScreen(own: true) => (
        profile == null ? 'You’re already going.' : 'You’re already going, ${firstName(profile.displayName)}.',
        'You claimed this invite on this phone.',
      ),
      _ => (
        'This invite has already been claimed.',
        'A vouch invite is for one person. If it was meant for you, ask $inviter for a new one. If you claimed it on another phone, continue with the same phone number or email to see your booking.',
      ),
    };

    final steps = <NextStep>[
      if (screen is SoldOutScreen)
        NextStep(
          icon: 'share',
          title: 'Tell $inviter',
          meta: 'Let them know it filled up',
          // The approved prefilled reply (S6 §12 Q3).
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  '${a.title} on ${formatDay(a.startsAt, a.timezone)} filled up before I could claim. Let’s find another date?',
            ),
          ),
        ),
      if (screen is ExpiredScreen && view.status == InviteViewStatusEnum.expired)
        NextStep(
          icon: 'host',
          title: 'See $inviter’s profile',
          meta: view.inviter.shortName,
          onTap: () => context.push('/users/${view.inviter.id}'),
        ),
      if (screen is ClaimedScreen && !(screen as ClaimedScreen).own) ...[
        NextStep(
          icon: 'share',
          title: 'Ask $inviter for a new invite',
          meta: 'Opens your share sheet',
          // New copy, not in the deck (owner review, S7 PLANNING change log).
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  'Hi $inviter, the invite for ${a.title} on ${formatDay(a.startsAt, a.timezone)} was already claimed. Could you send me a new one?',
            ),
          ),
        ),
        NextStep(
          icon: 'phone',
          title: 'Continue with your phone or email',
          meta: 'See bookings from another device',
          onTap: () => context.push('/signin?next=/me/plans'),
        ),
      ],
    ];
    final booking = a.viewer?.booking;
    final more = next;

    return ScreenBody(
      children: [
        if (screen is SoldOutScreen)
          HeroPhoto(url: a.photoUrl, dimmed: true, aspectRatio: 16 / 9, badge: const SpotsBadge(spots: 0)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${a.title} · ${formatDay(a.startsAt, a.timezone)}',
              style: VelioText.body.copyWith(color: VelioColors.muted),
            ),
            const SizedBox(height: VelioSpace.s2),
            Semantics(header: true, child: Text(headline, style: VelioText.title)),
            if (body != null) ...[
              const SizedBox(height: VelioSpace.s2),
              Text(body, style: VelioText.body.copyWith(color: VelioColors.muted)),
            ],
          ],
        ),
        if (screen is SoldOutScreen) AvatarStack(people: going(a.members), total: a.members.count),
        if (screen is ClaimedScreen && (screen as ClaimedScreen).own && booking != null)
          VButton('Open the plan', block: true, onPressed: () => context.push('/plans/${booking.planId}')),
        if (steps.isNotEmpty) ...[const SectionHeading('What you can do'), NextStepList(steps)],
        if (more != null && more.hostOtherDates.isNotEmpty) ...[
          SectionHeading('$host’s other dates'),
          NextStepList([for (final c in more.hostOtherDates) cardStep(context, c)]),
        ],
        if (more != null && more.moreInCommunity.isNotEmpty) ...[
          SectionHeading('More in ${a.community.name}'),
          NextStepList([for (final c in more.moreInCommunity) cardStep(context, c)]),
        ],
      ],
    );
  }
}
