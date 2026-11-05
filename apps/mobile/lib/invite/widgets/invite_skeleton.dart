import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

class InviteSkeleton extends StatelessWidget {
  const InviteSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the invite',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Row(children: [Skeleton(width: 36, height: 36, circle: true), SizedBox(width: 10), Skeleton(width: 180)]),
        Skeleton(height: 220, radius: VelioRadius.hero),
        Skeleton(height: 34, width: 260),
        Skeleton(height: 120, radius: VelioRadius.card),
        Skeleton(height: 52, radius: VelioRadius.pill),
      ],
    ),
  );
}
