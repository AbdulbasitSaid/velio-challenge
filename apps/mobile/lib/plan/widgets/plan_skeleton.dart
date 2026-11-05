import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

class PlanSkeleton extends StatelessWidget {
  const PlanSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: VAppBar(),
    body: ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 18, width: 140),
        Skeleton(height: 30, width: 260),
        Skeleton(height: 80, radius: VelioRadius.field),
        Skeleton(height: 200, radius: VelioRadius.card),
        Skeleton(height: 160, radius: VelioRadius.card),
      ],
    ),
  );
}
