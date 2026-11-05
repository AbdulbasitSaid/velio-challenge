// B4 Plan (S7 FR-013; UI design F-B4): members, how each joined and invite statuses, live; "Invite a
// friend" opens the vouch or public-link sheet.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/format.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/plan_repository.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/activity_display.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';
import '../../ui/spots_announcer.dart';
import '../bloc/plan_bloc.dart';
import '../widgets/invite_row.dart';
import 'invite_sheet_page.dart';
import '../widgets/member_source.dart';
import '../widgets/plan_loading.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PlanBloc(
      planRepository: context.read<PlanRepository>(),
      liveRepository: context.read<LiveRepository>(),
      planId: planId,
    )..add(const PlanRequested()),
    child: PlanDetailsView(planId: planId),
  );
}

class PlanDetailsView extends StatelessWidget {
  const PlanDetailsView({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlanBloc>();
    final state = context.watch<PlanBloc>().state;
    final plan = state.plan;
    final a = state.activity;
    if (plan == null || a == null) return PlanLoading(planId: planId);
    final me = context.select((SessionBloc b) => b.state.profile);
    final removed = plan.viewer.booking.status == PlanViewViewerBookingStatusEnum.removed;
    final online = context.select((ConnectivityCubit c) => c.state);
    final reconnecting = state.realtime == RealtimeStatus.reconnecting;
    final live = state.live;
    final spots = state.spots;
    final myInvites = plan.invites.where((i) => i.createdBy.id == me?.userId).toList();

    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back to My plans',
          onPressed: () => context.canPop() ? context.pop() : context.go('/me/plans'),
        ),
        title: 'Plan',
        trailing: LivePill(
          status: !online
              ? LiveStatus.offline
              : reconnecting
              ? LiveStatus.reconnecting
              : LiveStatus.live,
        ),
      ),
      body: SpotsAnnouncer(
        count: live,
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const PlanRequested());
              await bloc.stream.firstWhere((s) => !s.loading);
            },
            child: ScreenBody(
              children: [
                if (removed)
                  const VBanner(
                    tone: BannerTone.error,
                    title: 'The host removed this booking.',
                    body: 'Your spot was released. You can still book another date.',
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      removed ? 'Your plan' : 'You’re going to',
                      style: VelioText.bodyStrong.copyWith(color: VelioColors.forest),
                    ),
                    const SizedBox(height: 6),
                    Semantics(header: true, child: Text(a.title, style: VelioText.title)),
                    const SizedBox(height: 6),
                    Text(
                      '${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}',
                      style: VelioText.body.copyWith(color: VelioColors.muted),
                    ),
                  ],
                ),
                if (!removed) ...[
                  Wrap(
                    spacing: VelioSpace.s3,
                    runSpacing: VelioSpace.s3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      BookingRef(plan.viewer.booking.ref),
                      SpotsBadge(
                        spots: spots,
                        state: !online || reconnecting
                            ? SpotsState.stale
                            : (live?.changed ?? false)
                            ? SpotsState.changed
                            : SpotsState.live,
                      ),
                    ],
                  ),
                  LocationBlock(place: placeOf(a.location), offline: !online, aspectRatio: 16 / 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeading('Going · ${plan.members.length}'),
                      const SizedBox(height: VelioSpace.s3),
                      VList([
                        for (final m in plan.members)
                          MemberRow(
                            name: m.person.displayName,
                            seed: m.person.avatarSeed,
                            you: m.person.id == me?.userId,
                            meta: memberMeta(m),
                            chip: MemberSourceChip(m),
                          ),
                      ]),
                    ],
                  ),
                  if (plan.viewer.canInvite)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeading('Your invites'),
                        const SizedBox(height: VelioSpace.s3),
                        if (myInvites.isNotEmpty) ...[
                          VList([for (final i in myInvites) InviteRow(i)]),
                          const SizedBox(height: VelioSpace.s3),
                          Text(
                            '“Created” means the link exists; we can’t see whether it was sent.',
                            style: VelioText.caption.copyWith(color: VelioColors.muted),
                          ),
                          const SizedBox(height: VelioSpace.s3),
                        ],
                        if (spots > 0)
                          VButton(
                            'Invite a friend',
                            icon: 'share',
                            block: true,
                            onPressed: online ? () => showInviteSheet(context, plan, a) : null,
                          ),
                      ],
                    ),
                ] else ...[
                  NextStepList([
                    NextStep(
                      title: 'See other dates',
                      meta: '${a.host.shortName} · ${a.community.name}',
                      photoUrl: a.photoUrl,
                      onTap: () => context.push('/activities/${a.id}'),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
