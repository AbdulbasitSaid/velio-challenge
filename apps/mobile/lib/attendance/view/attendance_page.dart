// H1 live attendance (S7b FR-011, FR-012; web attendance-live.tsx; PRD H1, H2, D3, D5). Before the
// start each row offers Remove (always confirmed first); from the start, attended or no-show. The
// host sees names, refs and sources, never contacts (SEC-002).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';
import '../../repositories/live_repository.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../../ui/spots_announcer.dart';
import '../bloc/attendance_bloc.dart';
import '../widgets/attendance_content.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AttendanceBloc(
      hostRepository: context.read<HostRepository>(),
      liveRepository: context.read<LiveRepository>(),
      activityId: id,
      clock: context.read<AppConfig>().clock,
    )..add(const AttendanceRequested()),
    child: AttendanceView(id: id),
  );
}

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key, required this.id});
  final String id;

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceBloc>().state;
    final err = state.error;
    if (!state.ready && err != null) {
      final notFound = err == LoadError.notFound;
      return ErrorScreen(
        kind: notFound ? ErrorKind.notFound : (err == LoadError.offline ? ErrorKind.offline : ErrorKind.server),
        onRetry: notFound ? null : () => context.read<AttendanceBloc>().add(const AttendanceRequested()),
      );
    }
    final online = context.select((ConnectivityCubit c) => c.state);
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (a, b) => a.flashes != b.flashes,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.flash!))),
      child: Scaffold(
        appBar: VAppBar(
          leading: VIconButton(
            'back',
            label: 'My activities',
            onPressed: () => context.canPop() ? context.pop() : context.go('/host'),
          ),
          title: 'Attendance',
          trailing: state.data == null
              ? null
              : LivePill(
                  status: !online
                      ? LiveStatus.offline
                      : (state.reconnecting ? LiveStatus.reconnecting : LiveStatus.live),
                ),
        ),
        body: SafeArea(
          top: false,
          child: !state.ready
              ? const ScreenBody(
                  gap: VelioSpace.s4,
                  children: [
                    Skeleton(height: 34, width: 240),
                    Skeleton(height: 72, radius: VelioRadius.hero),
                    Skeleton(height: 220, radius: VelioRadius.card),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () {
                    final done = Completer<void>();
                    context.read<AttendanceBloc>().add(AttendanceRefreshed(done: done));
                    return done.future;
                  },
                  child: SpotsAnnouncer(
                    count: state.live,
                    child: AttendanceContent(id: widget.id, state: state, online: online, query: _query),
                  ),
                ),
        ),
      ),
    );
  }
}
