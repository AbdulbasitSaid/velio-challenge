// B6 My plans (S7 FR-014, FR-015; UI design F-B6): upcoming and past Plans with reference, members
// and spots; the saved list offline ("Showing your saved plans."); sign-in on a new phone (PRD Q14).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../domain/format.dart';
import '../../domain/load_error.dart';
import '../../repositories/plan_repository.dart';
import '../../repositories/session_repository.dart';
import '../../shell/shell.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../bloc/my_plans_bloc.dart';
import '../widgets/my_plan_card.dart';

class MyPlansPage extends StatelessWidget {
  const MyPlansPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        MyPlansBloc(
            planRepository: context.read<PlanRepository>(),
            sessionRepository: context.read<SessionRepository>(),
          )
          ..add(const MyPlansSubscriptionRequested())
          ..add(const MyPlansRequested()),
    child: const MyPlansView(),
  );
}

class MyPlansView extends StatelessWidget {
  const MyPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyPlansBloc>();
    final state = context.watch<MyPlansBloc>().state;
    final plans = state.plans;
    final err = state.error;
    if (state.signedIn && plans == null && err != null && err != LoadError.signIn) {
      return ErrorScreen(
        kind: err == LoadError.offline ? ErrorKind.offline : ErrorKind.server,
        onRetry: () => bloc.add(const MyPlansRequested()),
      );
    }
    final past = state.past;
    final list = plans == null ? null : (past ? plans.past : plans.upcoming);
    final now = context.read<AppConfig>().clock();
    final cachedAt = state.cachedAt;

    return Scaffold(
      appBar: const VAppBar(wordmark: true, trailing: RoleToggle()),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            bloc.add(const MyPlansRequested());
            await bloc.stream.firstWhere((s) => !s.loading);
          },
          child: ScreenBody(
            children: [
              Semantics(header: true, child: Text('My plans', style: VelioText.title)),
              if (!state.signedIn || err == LoadError.signIn) ...[
                const EmptyState(
                  icon: 'phone',
                  title: 'See your plans on this phone',
                  body: 'On another phone, continue with the same number or email you claimed with.',
                ),
                VButton(
                  'Continue with your phone or email',
                  block: true,
                  onPressed: () => context.push('/signin?next=/me/plans'),
                ),
              ] else ...[
                if (state.offline)
                  VBanner(
                    tone: BannerTone.offline,
                    title: cachedAt == null ? 'You’re offline' : 'You’re offline · ${updatedAgo(cachedAt, now)}',
                    body: 'Showing your saved plans.',
                  ),
                Segmented<bool>(
                  label: 'Show',
                  value: past,
                  options: const {false: 'Upcoming', true: 'Past'},
                  onChanged: (v) => bloc.add(MyPlansTabChanged(past: v)),
                ),
                if (list == null)
                  const Column(
                    children: [
                      Skeleton(height: 120, radius: VelioRadius.card),
                      SizedBox(height: VelioSpace.s3),
                      Skeleton(height: 120, radius: VelioRadius.card),
                    ],
                  )
                else if (plans!.upcoming.isEmpty && plans.past.isEmpty) ...[
                  const EmptyState(
                    icon: 'ticket',
                    title: 'No plans yet',
                    body: 'When you claim a spot from an invite, your plan shows up here.',
                  ),
                  VButton('Enter an invite code', block: true, onPressed: () => context.go('/')),
                ] else if (list.isEmpty)
                  Text(
                    past ? 'No past plans yet.' : 'Nothing coming up.',
                    style: VelioText.body.copyWith(color: VelioColors.muted),
                  )
                else
                  for (final p in list) MyPlanCard(plan: p, past: past),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
