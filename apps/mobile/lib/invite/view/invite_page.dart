// The invite (S7 FR-006, FR-007, FR-009, FR-015, FR-016; UI design F-G1, F-Outcomes): G1 (vouch) or
// G2 (public) with live spots, or G5 sold out, G6 expired, G7 claimed, or a paused link. The saved
// copy shows first on a revisit and whenever the phone is offline; Claim then waits for the network.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/invite_logic.dart';
import '../../repositories/invite_repository.dart';
import '../../repositories/live_repository.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../../ui/spots_announcer.dart';
import '../bloc/invite_bloc.dart';
import '../widgets/invite_outcome.dart';
import '../widgets/invite_skeleton.dart';
import '../widgets/open_invite.dart';

class InvitePage extends StatelessWidget {
  const InvitePage({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => InviteBloc(
      inviteRepository: context.read<InviteRepository>(),
      liveRepository: context.read<LiveRepository>(),
      code: code,
    )..add(const InviteRequested()),
    child: const InviteDetailsView(),
  );
}

class InviteDetailsView extends StatelessWidget {
  const InviteDetailsView({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      // FR-009: the open beacon after the first frame of the live invite.
      BlocListener<InviteBloc, InviteState>(
        listenWhen: (p, c) => p.live == null && c.live != null,
        listener: (context, _) {
          final bloc = context.read<InviteBloc>();
          WidgetsBinding.instance.addPostFrameCallback((_) => bloc.add(const InviteShown()));
        },
      ),
      // PRD M3: a distinct haptic as the invite lands on sold out.
      BlocListener<InviteBloc, InviteState>(
        listenWhen: (p, c) => p.live != null && p.screen is! SoldOutScreen && c.screen is SoldOutScreen,
        listener: (_, _) => HapticFeedback.heavyImpact(),
      ),
      // Back to code entry with the reason, as the web's G9 does.
      BlocListener<InviteBloc, InviteState>(
        listenWhen: (p, c) =>
            c.view == null && p.error != c.error && (c.error == InviteError.invalid || c.error == InviteError.limited),
        listener: (context, state) =>
            context.go('/?error=${state.error == InviteError.limited ? 'limited' : 'invalid'}'),
      ),
    ],
    child: const InviteDetailsBody(),
  );
}

class InviteDetailsBody extends StatelessWidget {
  const InviteDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InviteBloc>().state;
    final view = state.view;
    final err = state.error;
    if (view == null && err != null) {
      return switch (err) {
        InviteError.invalid || InviteError.limited => const Scaffold(body: SizedBox.shrink()),
        _ => ErrorScreen(
          kind: err == InviteError.offline ? ErrorKind.offline : ErrorKind.server,
          onRetry: () => context.read<InviteBloc>().add(const InviteRequested()),
        ),
      };
    }

    final online = context.select((ConnectivityCubit c) => c.state) && !state.offline;
    final live = state.live;
    final screen = state.screen;
    final reconnecting = state.realtime == RealtimeStatus.reconnecting;
    final pill = !online
        ? LiveStatus.offline
        : (reconnecting || live == null ? LiveStatus.reconnecting : LiveStatus.live);
    final cachedAt = state.cachedAt;
    final open = screen is OpenScreen;

    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: 'Invite',
        trailing: open
            ? LivePill(
                status: pill,
                minutes: !online && cachedAt != null
                    ? context.read<AppConfig>().clock().difference(cachedAt).inMinutes
                    : null,
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: SpotsAnnouncer(
          count: live,
          child: view == null || screen == null
              ? const InviteSkeleton()
              : switch (screen) {
                  OpenScreen(:final block) => OpenInvite(
                    view: view,
                    spots: state.spots,
                    spotsState: !online || reconnecting
                        ? SpotsState.stale
                        : (live?.changed ?? false)
                        ? SpotsState.changed
                        : SpotsState.live,
                    block: block,
                    online: online,
                    cachedAt: !online ? cachedAt : null,
                  ),
                  _ => InviteOutcome(view: view, screen: screen, next: state.next),
                },
        ),
      ),
    );
  }
}
