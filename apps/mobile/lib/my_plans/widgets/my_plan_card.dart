import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/format.dart';
import '../../ui/components.dart';

/// One Plan in My plans: reference, members and spots, or "Removed by host".
class MyPlanCard extends StatelessWidget {
  const MyPlanCard({super.key, required this.plan, required this.past});
  final MyPlan plan;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final a = plan.activity;
    final removed = plan.booking.status == PlanViewViewerBookingStatusEnum.removed;
    return PlanCard(
      title: a.title,
      meta: '${formatWhen(a.startsAt, a.timezone)} · ${a.location.venueName}',
      photoUrl: a.photoUrl,
      members: [for (final m in plan.members.preview) StackPerson(m.shortName, m.avatarSeed)],
      memberTotal: plan.members.count,
      code: removed ? null : plan.booking.ref,
      past: past,
      trailing: removed
          ? const VChip('Removed by host', tone: ChipTone.danger)
          : past
          ? null
          : SpotsBadge(spots: a.spotsLeft),
      onTap: () => context.push('/plans/${plan.planId}'),
    );
  }
}
