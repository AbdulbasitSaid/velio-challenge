// P1 profile (S7 FR-017, UI design F-P1): the short name, member since, what they host; never what
// they've booked (PRD Q10).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/providers.dart';
import '../ui/art.dart';
import '../ui/components.dart';
import 'errors.dart';
import 'invite.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  Profile? _profile;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(apiProvider).profile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final e = _error;
    if (p == null && e != null) {
      if (e.status == 404) return const ErrorScreen(kind: ErrorKind.notFound);
      return ErrorScreen(
        kind: e.network ? ErrorKind.offline : ErrorKind.server,
        onRetry: () {
          setState(() => _error = null);
          _load();
        },
      );
    }
    final first = p == null ? '' : firstName(p.person.shortName);
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: 'Profile',
      ),
      body: SafeArea(
        top: false,
        child: p == null
            ? const ScreenBody(
                children: [
                  Center(child: Skeleton(width: 88, height: 88, circle: true)),
                  Center(child: Skeleton(width: 160, height: 28)),
                  Skeleton(height: 100, radius: VelioRadius.card),
                ],
              )
            : ScreenBody(
                gap: VelioSpace.s6,
                children: [
                  Column(
                    children: [
                      Avatar(name: p.person.shortName, seed: p.person.avatarSeed, size: 88),
                      const SizedBox(height: 10),
                      Semantics(
                        header: true,
                        child: Text(p.person.shortName, style: VelioText.title, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On Velio since ${monthYear(p.memberSince)}',
                        style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
                      ),
                    ],
                  ),
                  if (p.hosting.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeading('Upcoming with $first'),
                        const SizedBox(height: 14),
                        NextStepList([for (final c in p.hosting) cardStep(context, c)]),
                      ],
                    )
                  else
                    Text(
                      '$first isn’t hosting anything right now.',
                      textAlign: TextAlign.center,
                      style: VelioText.body.copyWith(color: VelioColors.muted),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VIcon('lock', size: 16),
                      const SizedBox(width: VelioSpace.s2),
                      Expanded(
                        child: Text(
                          'Profiles never show which activities someone has booked.',
                          style: VelioText.caption.copyWith(color: VelioColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
