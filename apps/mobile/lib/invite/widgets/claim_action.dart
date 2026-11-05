import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/invite_logic.dart';
import '../../ui/components.dart';

/// Claim, or why it isn't offered: the host, already going, or bookings paused.
class ClaimAction extends StatelessWidget {
  const ClaimAction({super.key, required this.view, required this.block, required this.online});
  final InviteView view;
  final OpenBlock block;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final booking = view.activity.viewer?.booking;
    final Widget action = switch (block) {
      OpenBlock.host => Text(
        'You’re the host of this activity.',
        textAlign: TextAlign.center,
        style: VelioText.body.copyWith(color: VelioColors.muted),
      ),
      OpenBlock.alreadyGoing => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VBanner(title: 'You’re already going.', body: 'Your spot is booked. Invite friends from your plan.'),
          if (booking != null) ...[
            const SizedBox(height: VelioSpace.s3),
            VButton('Open the plan', block: true, onPressed: () => context.push('/plans/${booking.planId}')),
          ],
        ],
      ),
      OpenBlock.bookingsPaused => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VBanner(
            title: 'Bookings are paused for this activity.',
            body: 'Nothing has changed for people already going. Check back soon.',
          ),
          SizedBox(height: VelioSpace.s3),
          VButton('Bookings paused', block: true),
        ],
      ),
      OpenBlock.none =>
        online
            ? VButton('Claim my spot', block: true, onPressed: () => context.push('/i/${view.code}/claim'))
            : const VButton('Reconnect to claim', block: true),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        action,
        if (block == OpenBlock.none) ...[
          const SizedBox(height: 10),
          Text(
            'Spots aren’t held. Claim while they last.',
            textAlign: TextAlign.center,
            style: VelioText.caption.copyWith(color: VelioColors.muted),
          ),
        ],
      ],
    );
  }
}
