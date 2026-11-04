// H3 My activities (S7b FR-006; web host-list.tsx): upcoming and past, the phone's cards. After the
// start, a card asks for attendance until someone is marked, then shows how many came. Signed-out
// hosts are asked to sign in; everyone can host (PRD W1).
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
import 'shell.dart';

/// The card's status chip, as the approved canvas draws it (web `hostRow`).
({String status, ChipTone tone}) hostRow(HostActivityItem a, {required bool past}) {
  if (!past) {
    if (a.bookedCount == 0) return (status: 'No bookings yet', tone: ChipTone.neutral);
    return (status: spotsLabel(a.spotsLeft), tone: a.spotsLeft <= 0 ? ChipTone.forest : ChipTone.lime);
  }
  if (a.bookedCount == 0) return (status: 'No bookings', tone: ChipTone.neutral);
  if (a.markedCount == 0) return (status: 'Mark attendance', tone: ChipTone.danger);
  return (status: '${a.attendedCount} attended', tone: ChipTone.neutral);
}

class HostListScreen extends ConsumerStatefulWidget {
  const HostListScreen({super.key});
  @override
  ConsumerState<HostListScreen> createState() => _HostListState();
}

class _HostListState extends ConsumerState<HostListScreen> {
  HostActivityList? _data;
  ApiException? _error;
  bool _past = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ref.read(identityProvider).signedIn) return;
    try {
      final data = await ref.read(apiProvider).hostActivities();
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _create() async {
    await context.push('/host/new');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionVersionProvider, (_, _) {
      setState(() => _data = null);
      _load();
    });
    final signedIn = ref.watch(identityProvider).signedIn;
    final data = _data;
    final err = _error;
    if (signedIn && data == null && err != null && err.status != 401) {
      return ErrorScreen(
        kind: err.network ? ErrorKind.offline : ErrorKind.server,
        onRetry: () {
          setState(() => _error = null);
          _load();
        },
      );
    }
    final empty = data != null && data.upcoming.isEmpty && data.past.isEmpty;
    final items = data == null ? null : (_past ? data.past : data.upcoming);

    return Scaffold(
      appBar: const VAppBar(wordmark: true, trailing: RoleToggle()),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ScreenBody(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VelioSpace.s3,
                runSpacing: VelioSpace.s3,
                children: [
                  Semantics(header: true, child: Text('My activities', style: VelioText.title)),
                  if (signedIn && err?.status != 401) VButton('Create', icon: 'plus', small: true, onPressed: _create),
                ],
              ),
              if (!signedIn || err?.status == 401) ...[
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
              else if (empty) ...[
                const EmptyState(
                  icon: 'calendar',
                  title: 'No activities yet',
                  body: 'Create your first activity. It gets a page in its community and links you can share.',
                ),
                VButton('Create activity', block: true, onPressed: _create),
              ] else ...[
                Segmented<bool>(
                  label: 'Show',
                  value: _past,
                  options: const {false: 'Upcoming', true: 'Past'},
                  onChanged: (v) => setState(() => _past = v),
                ),
                if (items.isEmpty)
                  Text(
                    _past ? 'No past activities yet.' : 'Nothing coming up.',
                    style: VelioText.body.copyWith(color: VelioColors.muted),
                  )
                else
                  for (final a in items) _card(context, a),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, HostActivityItem a) {
    final row = hostRow(a, past: _past);
    return Material(
      color: VelioColors.surface,
      borderRadius: BorderRadius.circular(VelioRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(VelioRadius.card),
        onTap: () async {
          await context.push('/host/${a.id}/attendance');
          if (mounted) _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VelioRadius.small),
                    child: SizedBox.square(dimension: 56, child: Photo(url: a.photoUrl, small: true)),
                  ),
                  const SizedBox(width: VelioSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: VelioText.bodyStrong),
                        Text(
                          formatWhen(a.startsAt, a.timezone),
                          style: VelioText.caption.copyWith(color: VelioColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VelioSpace.s2,
                runSpacing: VelioSpace.s2,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${a.bookedCount}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' of ${a.capacity} booked'),
                      ],
                    ),
                    style: VelioText.body.copyWith(fontSize: 14),
                  ),
                  VChip(row.status, tone: row.tone),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
