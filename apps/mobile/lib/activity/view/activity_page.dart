// B1 activity page (S7b FR-004, FR-005): the page provides ActivityBloc; the view renders it and turns
// its results into navigation and haptics (PRD M3).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/load_error.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/session_repository.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../../ui/spots_announcer.dart';
import '../bloc/activity_bloc.dart';
import '../widgets/activity_content.dart';
import '../widgets/activity_skeleton.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ActivityBloc(
      activityRepository: context.read<ActivityRepository>(),
      liveRepository: context.read<LiveRepository>(),
      sessionRepository: context.read<SessionRepository>(),
      id: id,
    )..add(const ActivityRequested()),
    child: ActivityView(id: id),
  );
}

class ActivityView extends StatelessWidget {
  const ActivityView({super.key, required this.id});
  final String id;

  Future<void> _onEffect(BuildContext context, ActivityState state) async {
    final bloc = context.read<ActivityBloc>();
    switch (state.effect) {
      case ActivityEffect.signIn:
        await context.push('/signin?next=${Uri.encodeComponent('/activities/$id')}');
      case ActivityEffect.booked:
        HapticFeedback.mediumImpact();
        await context.push('/plans/${state.bookedPlanId}/welcome');
        if (context.mounted) bloc.add(const ActivityRequested());
      case ActivityEffect.soldOut:
        HapticFeedback.heavyImpact();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ActivityBloc, ActivityState>(
        listenWhen: (prev, curr) => prev.effectId != curr.effectId,
        listener: _onEffect,
      ),
      // PRD M3: a distinct haptic as the page lands on sold out.
      BlocListener<ActivityBloc, ActivityState>(
        listenWhen: (prev, curr) =>
            prev.live != null && curr.live != null && prev.live!.spotsLeft > 0 && curr.live!.spotsLeft <= 0,
        listener: (_, _) => HapticFeedback.heavyImpact(),
      ),
    ],
    child: const ActivityScaffold(),
  );
}

class ActivityScaffold extends StatelessWidget {
  const ActivityScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivityBloc>().state;
    final a = state.activity;
    if (state.status == ActivityStatus.failure) {
      final notFound = state.error == LoadError.notFound;
      return ErrorScreen(
        kind: notFound ? ErrorKind.notFound : (state.error == LoadError.offline ? ErrorKind.offline : ErrorKind.server),
        onRetry: notFound ? null : () => context.read<ActivityBloc>().add(const ActivityRequested()),
      );
    }
    final online = context.select((ConnectivityCubit c) => c.state);
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/explore'),
        ),
        title: a?.community.name ?? 'Activity',
        trailing: a == null
            ? null
            : LivePill(
                status: !online ? LiveStatus.offline : (state.reconnecting ? LiveStatus.reconnecting : LiveStatus.live),
              ),
      ),
      body: SafeArea(
        top: false,
        child: a == null
            ? const ActivitySkeleton()
            : RefreshIndicator(
                onRefresh: () {
                  final done = Completer<void>();
                  context.read<ActivityBloc>().add(ActivityRequested(done: done));
                  return done.future;
                },
                child: SpotsAnnouncer(
                  count: state.live,
                  child: ActivityContent(state: state, online: online),
                ),
              ),
      ),
    );
  }
}
