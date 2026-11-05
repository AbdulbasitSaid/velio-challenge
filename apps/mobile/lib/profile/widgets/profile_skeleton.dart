import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const ScreenBody(
    children: [
      Center(child: Skeleton(width: 88, height: 88, circle: true)),
      Center(child: Skeleton(width: 160, height: 28)),
      Skeleton(height: 100, radius: VelioRadius.card),
    ],
  );
}
