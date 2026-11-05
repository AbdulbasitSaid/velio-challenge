// The web's MoreToDo: the host's other dates and more in the community.
import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/activity_display.dart';
import '../../ui/components.dart';

class MoreToDo extends StatelessWidget {
  const MoreToDo({super.key, required this.activity, required this.next});
  final PublicActivity activity;
  final NextSteps? next;

  @override
  Widget build(BuildContext context) {
    final n = next;
    if (n == null) return const SizedBox.shrink();
    final a = activity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (n.hostOtherDates.isNotEmpty) ...[
          const SizedBox(height: VelioSpace.s4),
          Text('${firstName(a.host.shortName)}’s other dates', style: VelioText.subheading),
          const SizedBox(height: VelioSpace.s2),
          NextStepList([for (final c in n.hostOtherDates) cardStep(context, c)]),
        ],
        if (n.moreInCommunity.isNotEmpty) ...[
          const SizedBox(height: VelioSpace.s4),
          Text('More in ${a.community.name}', style: VelioText.subheading),
          const SizedBox(height: VelioSpace.s2),
          NextStepList([for (final c in n.moreInCommunity) cardStep(context, c)]),
        ],
      ],
    );
  }
}
