import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

class ActivitySkeleton extends StatelessWidget {
  const ActivitySkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the activity',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 220, radius: VelioRadius.hero),
        Skeleton(height: 34, width: 260),
        Skeleton(height: 120, radius: VelioRadius.card),
        Skeleton(height: 52, radius: VelioRadius.pill),
      ],
    ),
  );
}
