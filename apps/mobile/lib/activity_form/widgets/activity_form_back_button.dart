import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/components.dart';

/// Back to My activities.
class ActivityFormBackButton extends StatelessWidget {
  const ActivityFormBackButton({super.key});

  @override
  Widget build(BuildContext context) => VIconButton(
    'back',
    label: 'My activities',
    onPressed: () => context.canPop() ? context.pop() : context.go('/host'),
  );
}
