// H3 My activities (S7b FR-006; web host-list.tsx): upcoming and past, the phone's cards. After the
// start, a card asks for attendance until someone is marked, then shows how many came. Signed-out
// hosts are asked to sign in; everyone can host (PRD W1).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';
import '../../repositories/session_repository.dart';
import '../../shell/shell.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../bloc/host_list_bloc.dart';
import '../widgets/host_activity_card.dart';

class HostListPage extends StatelessWidget {
  const HostListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        HostListBloc(
            hostRepository: context.read<HostRepository>(),
            sessionRepository: context.read<SessionRepository>(),
          )
          ..add(const HostListRequested())
          ..add(const HostListSessionSubscriptionRequested()),
    child: const HostListView(),
  );
}

class HostListView extends StatelessWidget {
  const HostListView({super.key});

  /// Opens [path], then loads again: the host may have created, edited or marked something.
  static Future<void> openAndReload(BuildContext context, String path) async {
    final bloc = context.read<HostListBloc>();
    await context.push(path);
    if (!bloc.isClosed) bloc.add(const HostListRequested());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HostListBloc>().state;
    final err = state.error;
    if (state.signedIn && state.data == null && err != null && err != LoadError.signIn) {
      return ErrorScreen(
        kind: err == LoadError.offline ? ErrorKind.offline : ErrorKind.server,
        onRetry: () => context.read<HostListBloc>().add(const HostListRequested()),
      );
    }
    final items = state.items;
    final past = state.past;

    return Scaffold(
      appBar: const VAppBar(wordmark: true, trailing: RoleToggle()),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () {
            final done = Completer<void>();
            context.read<HostListBloc>().add(HostListRequested(done: done));
            return done.future;
          },
          child: ScreenBody(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VelioSpace.s3,
                runSpacing: VelioSpace.s3,
                children: [
                  Semantics(header: true, child: Text('My activities', style: VelioText.title)),
                  if (!state.needsSignIn)
                    VButton('Create', icon: 'plus', small: true, onPressed: () => openAndReload(context, '/host/new')),
                ],
              ),
              if (state.needsSignIn) ...[
                const EmptyState(
                  icon: 'host',
                  title: 'Host on Velio',
                  body: 'Continue with your phone or email to create activities and see who’s coming.',
                ),
                VButton(
                  'Continue with your phone or email',
                  block: true,
                  onPressed: () => context.push('/signin?next=/host'),
                ),
              ] else if (items == null)
                const Column(
                  children: [
                    Skeleton(height: 110, radius: VelioRadius.card),
                    SizedBox(height: VelioSpace.s3),
                    Skeleton(height: 110, radius: VelioRadius.card),
                  ],
                )
              else if (state.empty) ...[
                const EmptyState(
                  icon: 'calendar',
                  title: 'No activities yet',
                  body: 'Create your first activity. It gets a page in its community and links you can share.',
                ),
                VButton('Create activity', block: true, onPressed: () => openAndReload(context, '/host/new')),
              ] else ...[
                Segmented<bool>(
                  label: 'Show',
                  value: past,
                  options: const {false: 'Upcoming', true: 'Past'},
                  onChanged: (v) => context.read<HostListBloc>().add(HostListPastToggled(v)),
                ),
                if (items.isEmpty)
                  Text(
                    past ? 'No past activities yet.' : 'Nothing coming up.',
                    style: VelioText.body.copyWith(color: VelioColors.muted),
                  )
                else
                  for (final a in items)
                    HostActivityCard(
                      activity: a,
                      past: past,
                      onTap: () => openAndReload(context, '/host/${a.id}/attendance'),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
