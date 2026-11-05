import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

class ExploreSkeleton extends StatelessWidget {
  const ExploreSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the community',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 190, radius: VelioRadius.hero),
        Skeleton(height: 30, width: 220),
        Skeleton(height: 40),
        Skeleton(height: 260, radius: VelioRadius.card),
      ],
    ),
  );
}
