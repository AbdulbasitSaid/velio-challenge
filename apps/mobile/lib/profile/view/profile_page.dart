// P1 profile (S7 FR-017, UI design F-P1): the short name, member since, what they host; never what
// they've booked (PRD Q10).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/load_error.dart';
import '../../repositories/plan_repository.dart';
import '../../ui/components.dart';
import '../../ui/error_screen.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_content.dart';
import '../widgets/profile_skeleton.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ProfileBloc(planRepository: context.read<PlanRepository>(), userId: userId)..add(const ProfileRequested()),
    child: const ProfileView(),
  );
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileBloc>().state;
    final profile = state.profile;
    if (state.status == ProfileStatus.failure) {
      if (state.error == LoadError.notFound) return const ErrorScreen(kind: ErrorKind.notFound);
      return ErrorScreen(
        kind: state.error == LoadError.offline ? ErrorKind.offline : ErrorKind.server,
        onRetry: () => context.read<ProfileBloc>().add(const ProfileRequested()),
      );
    }
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: 'Profile',
      ),
      body: SafeArea(top: false, child: profile == null ? const ProfileSkeleton() : ProfileContent(profile: profile)),
    );
  }
}
