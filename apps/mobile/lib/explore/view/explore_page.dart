// C1 community (S7b FR-003; web community-live.tsx): cover, name, blurb, the count line and the list
// with live spots. With native maps on, a List / Map toggle. Explore (no slug) opens the first
// community, as web `/` does.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/load_error.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/live_repository.dart';
import '../../shell/shell.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../bloc/explore_bloc.dart';
import '../widgets/explore_content.dart';
import '../widgets/explore_skeleton.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, this.slug});

  /// Null on the Explore tab: the first community.
  final String? slug;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ExploreBloc(
      activityRepository: context.read<ActivityRepository>(),
      liveRepository: context.read<LiveRepository>(),
      slug: slug,
    )..add(const ExploreRequested()),
    child: ExploreView(tab: slug == null),
  );
}

class ExploreView extends StatelessWidget {
  const ExploreView({super.key, required this.tab});

  /// The Explore tab: the wordmark and the role toggle instead of Back.
  final bool tab;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExploreBloc>().state;
    final page = state.page;
    final appBar = tab
        ? const VAppBar(wordmark: true, trailing: RoleToggle())
        : VAppBar(
            leading: VIconButton(
              'back',
              label: 'Back',
              onPressed: () => context.canPop() ? context.pop() : context.go('/explore'),
            ),
            title: page?.community.name ?? 'Community',
          );
    if (state.status == ExploreStatus.failure) {
      final notFound = state.error == LoadError.notFound;
      return Scaffold(
        appBar: tab ? appBar : null,
        body: ErrorScreen(
          kind: notFound
              ? ErrorKind.notFound
              : (state.error == LoadError.offline ? ErrorKind.offline : ErrorKind.server),
          onRetry: notFound ? null : () => context.read<ExploreBloc>().add(const ExploreRequested()),
        ),
      );
    }
    final online = context.select((ConnectivityCubit c) => c.state);
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: state.status == ExploreStatus.none
            ? const ScreenBody(
                children: [EmptyState(icon: 'calendar', title: 'No communities yet.', body: 'Check back soon.')],
              )
            : page == null
            ? const ExploreSkeleton()
            : RefreshIndicator(
                onRefresh: () {
                  final done = Completer<void>();
                  context.read<ExploreBloc>().add(ExploreRequested(done: done));
                  return done.future;
                },
                child: ExploreContent(
                  state: state,
                  online: online,
                  maps: context.read<AppConfig>().mapsEnabled && online,
                ),
              ),
      ),
    );
  }
}
