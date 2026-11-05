import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';

import '../../ui/components.dart';

/// One of the viewer's invites, with its status.
class InviteRow extends StatelessWidget {
  const InviteRow(this.invite, {super.key});
  final PlanInvite invite;

  @override
  Widget build(BuildContext context) {
    final vouch = invite.rail == PlanInviteRailEnum.vouch;
    final status = invite.status.name;
    final (tone, label) = invite.paused
        ? (ChipTone.neutral, 'Paused')
        : switch (invite.status) {
            InviteStatus.created => (ChipTone.neutral, 'Created'),
            InviteStatus.opened => (ChipTone.sky, 'Opened'),
            InviteStatus.claimed => (ChipTone.lime, 'Claimed'),
            InviteStatus.expired => (ChipTone.neutral, 'Expired'),
          };
    return MemberRow(
      name: vouch ? 'Invite for ${invite.inviteeName ?? 'a friend'}' : 'Your public link',
      pending: true,
      meta: vouch
          ? 'Vouch${invite.code == null ? '' : ' · code ${invite.code}'}'
          : 'Public link · ${invite.opens} open${invite.opens == 1 ? '' : 's'} · ${invite.claims} claimed',
      chip: Semantics(
        label: 'Status $status',
        child: VChip(label, tone: tone),
      ),
    );
  }
}
