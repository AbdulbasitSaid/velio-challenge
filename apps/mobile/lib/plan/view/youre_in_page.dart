// G4 You're in (S7 FR-011; UI design F-G4): after a claim or a direct booking (S7b PLANNING §12 D4),
// the booking reference, the group, and "Invite a friend" while spots last.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/format.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/plan_repository.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/activity_display.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';
import '../../ui/spots_announcer.dart';
import '../bloc/plan_bloc.dart';
import 'invite_sheet_page.dart';
import '../widgets/plan_loading.dart';

class YoureInPage extends StatelessWidget {
  const YoureInPage({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PlanBloc(
      planRepository: context.read<PlanRepository>(),
      liveRepository: context.read<LiveRepository>(),
      planId: planId,
    )..add(const PlanRequested()),
    child: YoureInView(planId: planId),
  );
}

class YoureInView extends StatelessWidget {
  const YoureInView({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlanBloc>().state;
    final plan = state.plan;
    final a = state.activity;
    if (plan == null || a == null) return PlanLoading(planId: planId);
    final me = context.select((SessionBloc b) => b.state.profile);
    final online = context.select((ConnectivityCubit c) => c.state);
    final spots = state.spots;
    final booking = plan.viewer.booking;
    final others = plan.members.where((m) => m.person.id != me?.userId).toList();
    final names = [for (final m in others) firstName(m.person.displayName)];
    final groupLabel = names.isEmpty
        ? 'Just you so far'
        : '${names.length == 1 ? names.first : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}'} and you';

    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton('close', label: 'Close', onPressed: () => context.go('/')),
        title: 'You’re in',
      ),
      body: SpotsAnnouncer(
        count: state.live,
        child: SafeArea(
          top: false,
          child: ScreenBody(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s5, vertical: VelioSpace.s6),
                decoration: BoxDecoration(
                  color: VelioColors.lime,
                  borderRadius: BorderRadius.circular(VelioRadius.hero),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: VelioColors.forest, shape: BoxShape.circle),
                      child: const Center(child: VIcon('check', size: 26, color: VelioColors.lime)),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        me == null ? 'You’re in.' : 'You’re in, ${firstName(me.displayName)}.',
                        style: VelioText.title.copyWith(color: VelioColors.forest),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${a.title} with ${firstName(plan.owner.displayName)}’s group. ${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}.',
                      style: VelioText.body.copyWith(color: VelioColors.forest),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
                        decoration: BoxDecoration(
                          color: VelioColors.surface,
                          borderRadius: BorderRadius.circular(VelioRadius.field),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BOOKING REF',
                              style: VelioText.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.72,
                                color: VelioColors.muted,
                              ),
                            ),
                            SelectableText(booking.ref, style: VelioText.code.copyWith(color: VelioColors.forest)),
                            Text(
                              '${formatMoney(a.priceMinor, a.currency)}, paid to ${firstName(a.host.shortName)} on the day.',
                              style: VelioText.caption.copyWith(color: VelioColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LocationBlock(place: placeOf(a.location), offline: !online),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading('Your group'),
                  const SizedBox(height: VelioSpace.s3),
                  AvatarStack(
                    people: [for (final m in others) StackPerson(m.person.shortName, m.person.avatarSeed)],
                    total: others.length,
                    label: groupLabel,
                  ),
                  const SizedBox(height: VelioSpace.s3),
                  VButton(
                    'See the plan',
                    variant: ButtonVariant.secondary,
                    block: true,
                    onPressed: () => context.go('/plans/${plan.id}'),
                  ),
                ],
              ),
              if (plan.viewer.canInvite && spots > 0)
                Container(
                  padding: const EdgeInsets.all(VelioSpace.s4),
                  decoration: BoxDecoration(
                    color: VelioColors.surface,
                    borderRadius: BorderRadius.circular(VelioRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading('Who’s coming with you?'),
                      const SizedBox(height: 10),
                      Text(
                        '${spots == 1 ? 'Only 1 spot left' : 'Only $spots spots left'}. Invites don’t hold a spot, so tell friends now.',
                        style: VelioText.body.copyWith(color: VelioColors.muted),
                      ),
                      const SizedBox(height: 10),
                      VButton(
                        'Invite a friend',
                        icon: 'share',
                        block: true,
                        onPressed: () => showInviteSheet(context, plan, a),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
