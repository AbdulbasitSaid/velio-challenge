import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/format.dart';
import '../../ui/components.dart';

/// "Booked 4 Nov" or "Claimed 4 Nov".
String memberMeta(PlanViewMembersInner m) {
  final day = formatDay(m.joinedAt, 'UTC');
  return m.source_ == PlanViewMembersInnerSource_Enum.direct ? 'Booked $day' : 'Claimed $day';
}

/// How a member joined: direct, a vouch (and from whom), or the public link.
class MemberSourceChip extends StatelessWidget {
  const MemberSourceChip(this.member, {super.key});
  final PlanViewMembersInner member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    return switch (m.source_) {
      PlanViewMembersInnerSource_Enum.direct => const VChip('Direct'),
      PlanViewMembersInnerSource_Enum.vouch => VChip(
        m.invitedBy == null ? "Vouch" : "Via ${firstName(m.invitedBy!.shortName)}",
        tone: ChipTone.lime,
      ),
      PlanViewMembersInnerSource_Enum.public => const VChip('Public link', tone: ChipTone.sky),
    };
  }
}
