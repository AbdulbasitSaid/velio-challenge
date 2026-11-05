import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/load_error.dart';
import '../../ui/error_screen.dart';
import '../bloc/plan_bloc.dart';
import 'plan_skeleton.dart';

/// Before the Plan has loaded: the skeleton, the error screens, or (signed out) sign in and come back.
class PlanLoading extends StatelessWidget {
  const PlanLoading({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) {
    final error = context.select((PlanBloc b) => b.state.error);
    return BlocListener<PlanBloc, PlanState>(
      listenWhen: (p, c) => c.plan == null && p.error != c.error && c.error == LoadError.signIn,
      listener: (context, _) => context.go('/signin?next=${Uri.encodeComponent('/plans/$planId')}'),
      child: switch (error) {
        null => const PlanSkeleton(),
        LoadError.signIn => const SizedBox.shrink(),
        LoadError.notFound => const ErrorScreen(kind: ErrorKind.notFound),
        _ => ErrorScreen(
          kind: error == LoadError.offline ? ErrorKind.offline : ErrorKind.server,
          onRetry: () => context.read<PlanBloc>().add(const PlanRequested()),
        ),
      },
    );
  }
}
