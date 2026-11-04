// B6 My plans (S7 FR-014, FR-015; UI design F-B6): upcoming and past Plans with reference, members
// and spots; the saved list offline ("Showing your saved plans."); sign-in on a new phone (PRD Q14).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/providers.dart';
import '../ui/components.dart';
import 'errors.dart';
import 'shell.dart';

class MyPlansScreen extends ConsumerStatefulWidget {
  const MyPlansScreen({super.key});
  @override
  ConsumerState<MyPlansScreen> createState() => _MyPlansState();
}

class _MyPlansState extends ConsumerState<MyPlansScreen> {
  MyPlans? _plans;
  DateTime? _cachedAt;
  bool _offline = false;
  ApiException? _error;
  bool _past = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ref.read(identityProvider).signedIn) return;
    final cache = ref.read(cacheProvider);
    final cached = await cache.myPlans();
    if (cached != null && mounted && _plans == null) setState(() => _plans = cached.value);
    try {
      final plans = await ref.read(apiProvider).myPlans();
      await cache.saveMyPlans(plans, ref.read(clockProvider)());
      if (mounted) {
        setState(() {
          _plans = plans;
          _offline = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.network && cached != null) {
          _offline = true;
          _cachedAt = cached.fetchedAt;
        } else {
          _error = e;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionVersionProvider, (_, _) {
      setState(() => _plans = null);
      _load();
    });
    final signedIn = ref.watch(identityProvider).signedIn;
    final plans = _plans;
    final err = _error;
    if (signedIn && plans == null && err != null && err.status != 401) {
      return ErrorScreen(
        kind: err.network ? ErrorKind.offline : ErrorKind.server,
        onRetry: () {
          setState(() => _error = null);
          _load();
        },
      );
    }
    final list = plans == null ? null : (_past ? plans.past : plans.upcoming);
    final now = ref.read(clockProvider)();

    return Scaffold(
      appBar: const VAppBar(wordmark: true, trailing: RoleToggle()),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ScreenBody(
            children: [
              Semantics(header: true, child: Text('My plans', style: VelioText.title)),
              if (!signedIn || err?.status == 401) ...[
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
                if (_offline)
                  VBanner(
                    tone: BannerTone.offline,
                    title: _cachedAt == null ? 'You’re offline' : 'You’re offline · ${updatedAgo(_cachedAt!, now)}',
                    body: 'Showing your saved plans.',
                  ),
                Segmented<bool>(
                  label: 'Show',
                  value: _past,
                  options: const {false: 'Upcoming', true: 'Past'},
                  onChanged: (v) => setState(() => _past = v),
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
                    _past ? 'No past plans yet.' : 'Nothing coming up.',
                    style: VelioText.body.copyWith(color: VelioColors.muted),
                  )
                else
                  for (final p in list) _card(context, p),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, MyPlan p) {
    final a = p.activity;
    final removed = p.booking.status == PlanViewViewerBookingStatusEnum.removed;
    return PlanCard(
      title: a.title,
      meta: '${formatWhen(a.startsAt, a.timezone)} · ${a.location.venueName}',
      photoUrl: a.photoUrl,
      members: [for (final m in p.members.preview) StackPerson(m.shortName, m.avatarSeed)],
      memberTotal: p.members.count,
      code: removed ? null : p.booking.ref,
      past: _past,
      trailing: removed
          ? const VChip('Removed by host', tone: ChipTone.danger)
          : _past
          ? null
          : SpotsBadge(spots: a.spotsLeft),
      onTap: () => context.push('/plans/${p.planId}'),
    );
  }
}
