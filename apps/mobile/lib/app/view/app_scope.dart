// The app's dependencies (bloc architecture): repositories once at the root, and the app-wide blocs
// above the router. Tests build the same scope with fakes.
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/connectivity_repository.dart';
import '../../repositories/host_repository.dart';
import '../../repositories/invite_repository.dart';
import '../../repositories/live_repository.dart';
import '../../repositories/plan_repository.dart';
import '../../repositories/preferences_repository.dart';
import '../../repositories/session_repository.dart';
import '../../role/cubit/role_cubit.dart';
import '../../session/bloc/session_bloc.dart';
import '../config.dart';

class AppScope extends StatelessWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.sessionRepository,
    required this.preferencesRepository,
    required this.connectivityRepository,
    required this.liveRepository,
    required this.inviteRepository,
    required this.activityRepository,
    required this.planRepository,
    required this.hostRepository,
    required this.role,
    required this.child,
  });

  final AppConfig config;
  final SessionRepository sessionRepository;
  final PreferencesRepository preferencesRepository;
  final ConnectivityRepository connectivityRepository;
  final LiveRepository liveRepository;
  final InviteRepository inviteRepository;
  final ActivityRepository activityRepository;
  final PlanRepository planRepository;
  final HostRepository hostRepository;

  /// The saved role, loaded before the first frame (S7b FR-001).
  final Role role;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: config),
      RepositoryProvider.value(value: sessionRepository),
      RepositoryProvider.value(value: preferencesRepository),
      RepositoryProvider.value(value: connectivityRepository),
      RepositoryProvider.value(value: liveRepository),
      RepositoryProvider.value(value: inviteRepository),
      RepositoryProvider.value(value: activityRepository),
      RepositoryProvider.value(value: planRepository),
      RepositoryProvider.value(value: hostRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SessionBloc(sessionRepository: sessionRepository)..add(const SessionSubscriptionRequested()),
        ),
        BlocProvider(
          create: (_) => RoleCubit(preferencesRepository: preferencesRepository, initial: role),
        ),
        BlocProvider(create: (_) => ConnectivityCubit(connectivityRepository: connectivityRepository)),
      ],
      child: child,
    ),
  );
}
