// G4 You're in and B4 Plan (S7 FR-011, FR-013; UI design F-G4, F-B4), with the "Invite a friend"
// sheets: a vouch for one named friend, or the Plan's public link, both handed to the phone's share
// sheet. Velio sends nothing itself (PRD Notifications); the contact goes only to the API.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/live.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../core/realtime.dart';
import '../ui/art.dart';
import '../ui/components.dart';
import '../ui/location.dart';
import 'errors.dart';
import 'invite.dart';

/// The Plan with its activity snapshot (the Plan view carries no location) and live spots.
class _PlanData {
  _PlanData(this.plan, this.activity);
  final PlanView plan;
  final PublicActivity activity;
}

mixin _PlanLoader<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String get planId;
  _PlanData? data;
  ApiException? error;
  LiveSpots? live;

  Future<void> loadPlan() async {
    try {
      final api = ref.read(apiProvider);
      final plan = await api.plan(planId);
      final activity = await api.activity(plan.activity.id);
      if (!mounted) return;
      setState(() {
        data = _PlanData(plan, activity);
        error = null;
      });
      final l = live;
      if (l == null) {
        live = LiveSpots(
          realtime: ref.read(realtimeProvider),
          activityId: activity.id,
          planId: plan.id,
          spotsLeft: activity.spotsLeft,
          version: activity.version,
          refresh: _refresh,
          onPlan: _refresh,
          view: View.maybeOf(context),
        )..addListener(() => mounted ? setState(() {}) : null);
      } else {
        l.apply(activity.spotsLeft, activity.version);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> _refresh() async {
    try {
      await loadPlan();
    } catch (_) {}
  }

  @override
  void dispose() {
    live?.dispose();
    super.dispose();
  }

  Widget? loadingOrError() {
    final e = error;
    if (data != null) return null;
    if (e == null) return const _PlanSkeleton();
    if (e.status == 401) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/signin?next=${Uri.encodeComponent('/plans/$planId')}');
      });
      return const SizedBox.shrink();
    }
    if (e.status == 403 || e.status == 404 || e.code == 'not_found' || e.code == 'forbidden') {
      return const ErrorScreen(kind: ErrorKind.notFound);
    }
    return ErrorScreen(
      kind: e.network ? ErrorKind.offline : ErrorKind.server,
      onRetry: () {
        setState(() => error = null);
        loadPlan();
      },
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();
  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: VAppBar(),
    body: ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 18, width: 140),
        Skeleton(height: 30, width: 260),
        Skeleton(height: 80, radius: VelioRadius.field),
        Skeleton(height: 200, radius: VelioRadius.card),
        Skeleton(height: 160, radius: VelioRadius.card),
      ],
    ),
  );
}

String _memberMeta(PlanViewMembersInner m) {
  final day = formatDay(m.joinedAt, 'UTC');
  return m.source_ == PlanViewMembersInnerSource_Enum.direct ? 'Booked $day' : 'Claimed $day';
}

Widget _sourceChip(PlanViewMembersInner m) => switch (m.source_) {
  PlanViewMembersInnerSource_Enum.direct => const VChip('Direct'),
  PlanViewMembersInnerSource_Enum.vouch => VChip(
    m.invitedBy == null ? "Vouch" : "Via ${firstName(m.invitedBy!.shortName)}",
    tone: ChipTone.lime,
  ),
  PlanViewMembersInnerSource_Enum.public => const VChip('Public link', tone: ChipTone.sky),
};

// ---------------------------------------------------------------- G4

class YoureInScreen extends ConsumerStatefulWidget {
  const YoureInScreen({super.key, required this.planId});
  final String planId;
  @override
  ConsumerState<YoureInScreen> createState() => _YoureInState();
}

class _YoureInState extends ConsumerState<YoureInScreen> with _PlanLoader {
  @override
  String get planId => widget.planId;

  @override
  void initState() {
    super.initState();
    loadPlan();
  }

  @override
  Widget build(BuildContext context) {
    final wait = loadingOrError();
    if (wait != null) return wait;
    final plan = data!.plan;
    final a = data!.activity;
    final me = ref.read(identityProvider).profile;
    final spots = live?.spotsLeft ?? a.spotsLeft;
    final booking = plan.viewer.booking;
    final others = plan.members.where((m) => m.person.id != me?.userId).toList();
    final names = [for (final m in others) firstName(m.person.displayName)];
    final groupLabel = names.isEmpty
        ? 'Just you so far'
        : '${names.length == 1 ? names.first : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}'} and you';

    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton('close', label: 'Close', onPressed: () => context.go('/')),
        title: 'You’re in',
      ),
      body: SafeArea(
        top: false,
        child: ScreenBody(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s5, vertical: VelioSpace.s6),
              decoration: BoxDecoration(color: VelioColors.lime, borderRadius: BorderRadius.circular(VelioRadius.hero)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: VelioColors.forest, shape: BoxShape.circle),
                    child: const Center(child: VIcon('check', size: 26, color: VelioColors.lime)),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      me == null ? 'You’re in.' : 'You’re in, ${firstName(me.displayName)}.',
                      style: VelioText.title.copyWith(color: VelioColors.forest),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${a.title} with ${firstName(plan.owner.displayName)}’s group. ${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}.',
                    style: VelioText.body.copyWith(color: VelioColors.forest),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
                      decoration: BoxDecoration(
                        color: VelioColors.surface,
                        borderRadius: BorderRadius.circular(VelioRadius.field),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BOOKING REF',
                            style: VelioText.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.72,
                              color: VelioColors.muted,
                            ),
                          ),
                          SelectableText(booking.ref, style: VelioText.code.copyWith(color: VelioColors.forest)),
                          Text(
                            '${formatMoney(a.priceMinor, a.currency)}, paid to ${firstName(a.host.shortName)} on the day.',
                            style: VelioText.caption.copyWith(color: VelioColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            LocationBlock(place: placeOf(a.location), offline: !isOnline(ref)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeading('Your group'),
                const SizedBox(height: VelioSpace.s3),
                AvatarStack(
                  people: [for (final m in others) StackPerson(m.person.shortName, m.person.avatarSeed)],
                  total: others.length,
                  label: groupLabel,
                ),
                const SizedBox(height: VelioSpace.s3),
                VButton(
                  'See the plan',
                  variant: ButtonVariant.secondary,
                  block: true,
                  onPressed: () => context.go('/plans/${plan.id}'),
                ),
              ],
            ),
            if (plan.viewer.canInvite && spots > 0)
              Container(
                padding: const EdgeInsets.all(VelioSpace.s4),
                decoration: BoxDecoration(
                  color: VelioColors.surface,
                  borderRadius: BorderRadius.circular(VelioRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeading('Who’s coming with you?'),
                    const SizedBox(height: 10),
                    Text(
                      '${spots == 1 ? 'Only 1 spot left' : 'Only $spots spots left'}. Invites don’t hold a spot, so tell friends now.',
                      style: VelioText.body.copyWith(color: VelioColors.muted),
                    ),
                    const SizedBox(height: 10),
                    VButton(
                      'Invite a friend',
                      icon: 'share',
                      block: true,
                      onPressed: () => showInviteSheet(context, ref, plan, a),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- B4

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key, required this.planId});
  final String planId;
  @override
  ConsumerState<PlanScreen> createState() => _PlanState();
}

class _PlanState extends ConsumerState<PlanScreen> with _PlanLoader {
  @override
  String get planId => widget.planId;

  @override
  void initState() {
    super.initState();
    loadPlan();
  }

  @override
  Widget build(BuildContext context) {
    final wait = loadingOrError();
    if (wait != null) return wait;
    final plan = data!.plan;
    final a = data!.activity;
    final me = ref.read(identityProvider).profile;
    final removed = plan.viewer.booking.status == PlanViewViewerBookingStatusEnum.removed;
    final online = isOnline(ref);
    final reconnecting = live?.status == RealtimeStatus.reconnecting;
    final spots = live?.spotsLeft ?? a.spotsLeft;
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
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: loadPlan,
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
                          meta: _memberMeta(m),
                          chip: _sourceChip(m),
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
                        VList([for (final i in myInvites) _InviteRow(i)]),
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
                          onPressed: online ? () => showInviteSheet(context, ref, plan, a) : null,
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
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow(this.invite);
  final PlanInvite invite;

  @override
  Widget build(BuildContext context) {
    final vouch = invite.rail == PlanInviteRailEnum.vouch;
    final status = invite.status.name;
    final (tone, label) = invite.paused
        ? (ChipTone.neutral, 'Paused')
        : switch (invite.status) {
            InviteStatus.created => (ChipTone.neutral, 'Created'),
            InviteStatus.opened => (ChipTone.sky, 'Opened'),
            InviteStatus.claimed => (ChipTone.lime, 'Claimed'),
            InviteStatus.expired => (ChipTone.neutral, 'Expired'),
          };
    return MemberRow(
      name: vouch ? 'Invite for ${invite.inviteeName ?? 'a friend'}' : 'Your public link',
      pending: true,
      meta: vouch
          ? 'Vouch${invite.code == null ? '' : ' · code ${invite.code}'}'
          : 'Public link · ${invite.opens} open${invite.opens == 1 ? '' : 's'} · ${invite.claims} claimed',
      chip: Semantics(
        label: 'Status $status',
        child: VChip(label, tone: tone),
      ),
    );
  }
}

// ---------------------------------------------------------------- Invite sheets

Future<void> showInviteSheet(BuildContext context, WidgetRef ref, PlanView plan, PublicActivity a) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VelioColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (_) => _InviteSheet(plan: plan, activity: a),
    );

enum _Step { choose, vouch, link }

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.plan, required this.activity});
  final PlanView plan;
  final PublicActivity activity;
  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  var _step = _Step.choose;
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _nameError;
  String? _contactError;
  String? _error;
  Invite? _link;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _createVouch() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Add their name, so the invite is addressed to them.');
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _contactError = null;
      _error = null;
    });
    try {
      final inv = await ref.read(apiProvider).createInvite(widget.plan.id, {
        'rail': 'vouch',
        'inviteeName': name,
        'contact': _contact.text.trim().isEmpty ? null : _contact.text.trim(),
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      });
      final a = widget.activity;
      // The contact never goes into the message; the guest picks the recipient in the share sheet.
      await SharePlus.instance.share(ShareParams(text: vouchMessage(name, a.title, a.startsAt, a.timezone, inv.link)));
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() {
        if (e.code == 'invalid_contact') {
          _contactError = 'Enter a full phone number with country code, or an email address.';
        } else {
          _error = e.network ? 'Check your connection and try again.' : 'We couldn’t create the invite.';
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLink() async {
    setState(() {
      _step = _Step.link;
      _busy = true;
      _error = null;
    });
    try {
      // Returns the caller's existing public link (S5 T12).
      final inv = await ref.read(apiProvider).createInvite(widget.plan.id, {'rail': 'public'});
      if (mounted) setState(() => _link = inv);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.network ? 'Check your connection and try again.' : 'We couldn’t get your link.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resume() async {
    final l = _link;
    if (l == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).resumeInvite(l.code);
      await _openLink();
    } on ApiException {
      if (mounted) setState(() => _error = 'We couldn’t resume the link.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final l = _link;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s3, VelioSpace.s5, VelioSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: VelioColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: VelioSpace.s4),
              if (_error != null) ...[
                VBanner(tone: BannerTone.error, title: _error!),
                const SizedBox(height: VelioSpace.s3),
              ],
              ...switch (_step) {
                _Step.choose => [
                  Text('Invite a friend', style: VelioText.heading),
                  const SizedBox(height: VelioSpace.s2),
                  Text(
                    'Invites don’t hold a spot, so tell friends now.',
                    style: VelioText.body.copyWith(color: VelioColors.muted),
                  ),
                  const SizedBox(height: VelioSpace.s4),
                  NextStepList([
                    NextStep(
                      icon: 'host',
                      title: 'Vouch for a friend',
                      meta: 'One invite, one person. It shows your name, so they know it’s from you.',
                      onTap: () => setState(() => _step = _Step.vouch),
                    ),
                    NextStep(
                      icon: 'share',
                      title: 'Share a link',
                      meta: 'For a group chat. Anyone with it can claim a spot while spots last.',
                      onTap: _openLink,
                    ),
                  ]),
                ],
                _Step.vouch => [
                  Text('Vouch for a friend', style: VelioText.heading),
                  const SizedBox(height: VelioSpace.s4),
                  VTextField(
                    label: 'Friend’s name',
                    controller: _name,
                    placeholder: 'Who is it for?',
                    error: _nameError,
                    maxLength: 80,
                  ),
                  const SizedBox(height: VelioSpace.s4),
                  VTextField(
                    label: 'Their phone or email (optional)',
                    controller: _contact,
                    placeholder: '+254 7… or name@example.com',
                    help: 'Used only to send and match this invite. ${firstName(a.host.shortName)} never sees it.',
                    error: _contactError,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: VelioSpace.s4),
                  VTextField(
                    label: 'Note (optional)',
                    controller: _note,
                    placeholder: 'A line from you, shown on their invite',
                    multiline: true,
                    maxLength: 280,
                  ),
                  const SizedBox(height: VelioSpace.s5),
                  VButton(
                    _busy ? 'Creating…' : 'Create and share',
                    block: true,
                    loading: _busy,
                    onPressed: _createVouch,
                  ),
                ],
                _Step.link => [
                  Text('Your link', style: VelioText.heading),
                  const SizedBox(height: VelioSpace.s3),
                  if (l == null && _busy)
                    const Skeleton(height: 52, radius: VelioRadius.field)
                  else if (l != null && l.paused) ...[
                    VBanner(
                      title: l.pausedReason == PauseReason.host
                          ? 'The host paused this link.'
                          : 'You paused this link.',
                      body: l.pausedReason == PauseReason.host
                          ? 'Bookings already made are safe. Vouch invites still work.'
                          : 'Nobody can claim from it until you resume it. Bookings already made are safe.',
                    ),
                    if (l.pausedReason != PauseReason.host) ...[
                      const SizedBox(height: VelioSpace.s3),
                      VButton('Resume link', block: true, loading: _busy, onPressed: _resume),
                    ],
                  ] else if (l != null) ...[
                    SelectableText(l.link.replaceFirst(RegExp(r'^https?://'), ''), style: VelioText.bodyStrong),
                    const SizedBox(height: VelioSpace.s4),
                    VButton(
                      'Share',
                      icon: 'share',
                      block: true,
                      onPressed: () =>
                          SharePlus.instance.share(ShareParams(text: 'Join the group going to ${a.title}: ${l.link}')),
                    ),
                  ],
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
