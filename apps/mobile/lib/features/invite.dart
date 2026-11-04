// The invite (S7 FR-006, FR-007, FR-009, FR-015, FR-016; UI design F-G1, F-Outcomes): G1 (vouch) or
// G2 (public) with live spots, or G5 sold out, G6 expired, G7 claimed, or a paused link. The saved
// copy shows first on a revisit and whenever the phone is offline; Claim then waits for the network.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/invite_logic.dart';
import '../core/live.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../core/realtime.dart';
import '../ui/components.dart';
import '../ui/location.dart';
import 'errors.dart';

Place placeOf(PublicLocation l) => Place(
  venue: l.venueName,
  address: l.addressText,
  lat: l.lat.toDouble(),
  lng: l.lng.toDouble(),
  directionsUrl: l.directionsUrl,
  meetingPoint: l.meetingPoint,
);

List<DetailRow> activityRows(PublicActivity a) => [
  DetailRow('calendar', formatWhen(a.startsAt, a.timezone), zoneLabel(a.timezone)),
  DetailRow('price', '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day'),
  DetailRow('host', 'Hosted by ${a.host.shortName}'),
];

List<StackPerson> going(PublicActivityMembers m) => [for (final p in m.preview) StackPerson(p.shortName, p.avatarSeed)];

class InviteScreenPage extends ConsumerStatefulWidget {
  const InviteScreenPage({super.key, required this.code});
  final String code;

  @override
  ConsumerState<InviteScreenPage> createState() => _InviteState();
}

class _InviteState extends ConsumerState<InviteScreenPage> {
  InviteView? _view;
  DateTime? _cachedAt;
  bool _offline = false;
  ApiException? _error;
  LiveSpots? _live;
  NextSteps? _next;
  bool _opened = false;
  bool _wasSoldOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _live?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cached = await ref.read(cacheProvider).invite(widget.code);
    if (cached != null && mounted && _view == null) setState(() => _view = cached.value);
    try {
      await _fetch();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.network && cached != null) {
        setState(() {
          _offline = true;
          _cachedAt = cached.fetchedAt;
        });
      } else {
        setState(() => _error = e);
      }
    }
  }

  Future<void> _fetch() async {
    final view = await ref.read(apiProvider).invite(widget.code);
    await ref.read(cacheProvider).saveInvite(view, ref.read(clockProvider)());
    if (!mounted) return;
    setState(() {
      _view = view;
      _offline = false;
      _error = null;
    });
    final live = _live;
    if (live == null) {
      _live = LiveSpots(
        realtime: ref.read(realtimeProvider),
        activityId: view.activity.id,
        spotsLeft: view.activity.spotsLeft,
        version: view.activity.version,
        refresh: _refresh,
        view: View.maybeOf(context),
      )..addListener(_onLive);
    } else {
      live.apply(view.activity.spotsLeft, view.activity.version);
    }
    _beacon();
  }

  Future<void> _refresh() async {
    try {
      await _fetch();
    } on ApiException catch (e) {
      if (e.network && mounted) setState(() => _offline = true);
    }
  }

  /// FR-009: once, after the first frame of the live invite.
  void _beacon() {
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiProvider).open(widget.code, ref.read(platformProvider));
    });
  }

  void _onLive() {
    if (!mounted) return;
    final view = _view;
    final soldOut = view != null && selectScreen(view, spotsLeft: _live!.spotsLeft) is SoldOutScreen;
    // PRD M3: a distinct haptic as the invite lands on sold out.
    if (soldOut && !_wasSoldOut) HapticFeedback.heavyImpact();
    _wasSoldOut = soldOut;
    setState(() {});
  }

  Future<void> _loadNext(String activityId) async {
    if (_next != null) return;
    try {
      final n = await ref.read(apiProvider).nextSteps(activityId);
      if (mounted) setState(() => _next = n);
    } catch (_) {
      // Next steps are extras (UX FR-007).
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final err = _error;
    if (view == null && err != null) {
      if (err.network) {
        return ErrorScreen(
          kind: ErrorKind.offline,
          onRetry: () => setState(() {
            _error = null;
            _load();
          }),
        );
      }
      if (err.code == 'invalid_code' || err.code == 'not_found' || err.code == 'rate_limited') {
        // Back to code entry with the reason, as the web's G9 does.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/?error=${err.code == 'rate_limited' ? 'limited' : 'invalid'}');
        });
        return const Scaffold(body: SizedBox.shrink());
      }
      return ErrorScreen(
        kind: ErrorKind.server,
        onRetry: () => setState(() {
          _error = null;
          _load();
        }),
      );
    }

    final online = isOnline(ref) && !_offline;
    final live = _live;
    final spots = live?.spotsLeft ?? view?.activity.spotsLeft ?? 0;
    final screen = view == null ? null : selectScreen(view, spotsLeft: spots);
    final reconnecting = live?.status == RealtimeStatus.reconnecting;
    final pill = !online
        ? LiveStatus.offline
        : (reconnecting || live == null ? LiveStatus.reconnecting : LiveStatus.live);

    final open = screen is OpenScreen;
    if (view != null && screen != null && !open) _loadNext(view.activity.id);

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
                minutes: !online && _cachedAt != null
                    ? ref.read(clockProvider)().difference(_cachedAt!).inMinutes
                    : null,
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: view == null || screen == null
            ? const _InviteSkeleton()
            : switch (screen) {
                OpenScreen(:final block) => _OpenInvite(
                  view: view,
                  spots: spots,
                  spotsState: !online || reconnecting
                      ? SpotsState.stale
                      : (live?.changed ?? false)
                      ? SpotsState.changed
                      : SpotsState.live,
                  block: block,
                  online: online,
                  cachedAt: !online ? _cachedAt : null,
                ),
                _ => _Outcome(view: view, screen: screen, next: _next),
              },
      ),
    );
  }
}

class _InviteSkeleton extends StatelessWidget {
  const _InviteSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the invite',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Row(children: [Skeleton(width: 36, height: 36, circle: true), SizedBox(width: 10), Skeleton(width: 180)]),
        Skeleton(height: 220, radius: VelioRadius.hero),
        Skeleton(height: 34, width: 260),
        Skeleton(height: 120, radius: VelioRadius.card),
        Skeleton(height: 52, radius: VelioRadius.pill),
      ],
    ),
  );
}

class _OpenInvite extends ConsumerWidget {
  const _OpenInvite({
    required this.view,
    required this.spots,
    required this.spotsState,
    required this.block,
    required this.online,
    required this.cachedAt,
  });
  final InviteView view;
  final int spots;
  final SpotsState spotsState;
  final OpenBlock block;
  final bool online;
  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = view.activity;
    final vouch = view.rail == InviteViewRailEnum.vouch;
    final inviter = view.inviter;
    return ScreenBody(
      children: [
        if (!online)
          VBanner(
            tone: BannerTone.offline,
            title: cachedAt == null
                ? 'You’re offline'
                : 'You’re offline · ${updatedAgo(cachedAt!, ref.read(clockProvider)())}',
            body: 'Showing the saved invite. Reconnect to claim.',
          ),
        if (vouch)
          Row(
            children: [
              Avatar(name: inviter.shortName, seed: inviter.avatarSeed, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: firstName(inviter.shortName),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' wants you on'),
                    ],
                  ),
                  style: VelioText.body.copyWith(fontSize: 17, height: 24 / 17, color: VelioColors.forest),
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VChip(a.community.name, tone: ChipTone.outline, icon: 'people'),
              const SizedBox(height: 10),
              Text(
                'Join the group going to',
                style: VelioText.body.copyWith(fontSize: 17, height: 24 / 17, color: VelioColors.forest),
              ),
            ],
          ),
        HeroPhoto(
          url: a.photoUrl,
          badge: SpotsBadge(spots: spots, state: spotsState),
        ),
        Semantics(
          header: true,
          child: Text(a.title, style: VelioText.display.copyWith(fontSize: 34, height: 38 / 34)),
        ),
        if (view.note != null && view.note!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(VelioSpace.s4),
            decoration: BoxDecoration(
              color: VelioColors.surface,
              borderRadius: BorderRadius.circular(VelioRadius.card),
            ),
            child: Text('“${view.note}” · ${firstName(inviter.shortName)}', style: VelioText.body),
          ),
        DetailRows(activityRows(a)),
        AvatarStack(people: going(a.members), total: a.members.count),
        _ClaimAction(view: view, block: block, online: online),
        LocationBlock(place: placeOf(a.location), offline: !online),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('About'),
            const SizedBox(height: VelioSpace.s2),
            Text(a.description, style: VelioText.body),
          ],
        ),
      ],
    );
  }
}

class _ClaimAction extends StatelessWidget {
  const _ClaimAction({required this.view, required this.block, required this.online});
  final InviteView view;
  final OpenBlock block;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final booking = view.activity.viewer?.booking;
    final Widget action = switch (block) {
      OpenBlock.host => Text(
        'You’re the host of this activity.',
        textAlign: TextAlign.center,
        style: VelioText.body.copyWith(color: VelioColors.muted),
      ),
      OpenBlock.alreadyGoing => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VBanner(title: 'You’re already going.', body: 'Your spot is booked. Invite friends from your plan.'),
          if (booking != null) ...[
            const SizedBox(height: VelioSpace.s3),
            VButton('Open the plan', block: true, onPressed: () => context.push('/plans/${booking.planId}')),
          ],
        ],
      ),
      OpenBlock.bookingsPaused => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VBanner(
            title: 'Bookings are paused for this activity.',
            body: 'Nothing has changed for people already going. Check back soon.',
          ),
          SizedBox(height: VelioSpace.s3),
          VButton('Bookings paused', block: true),
        ],
      ),
      OpenBlock.none =>
        online
            ? VButton('Claim my spot', block: true, onPressed: () => context.push('/i/${view.code}/claim'))
            : const VButton('Reconnect to claim', block: true),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        action,
        if (block == OpenBlock.none) ...[
          const SizedBox(height: 10),
          Text(
            'Spots aren’t held. Claim while they last.',
            textAlign: TextAlign.center,
            style: VelioText.caption.copyWith(color: VelioColors.muted),
          ),
        ],
      ],
    );
  }
}

/// G5, G6, G7 and the paused link (UI design F-Outcomes).
class _Outcome extends ConsumerWidget {
  const _Outcome({required this.view, required this.screen, required this.next});
  final InviteView view;
  final InviteScreen screen;
  final NextSteps? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = view.activity;
    final inviter = firstName(view.inviter.shortName);
    final host = firstName(a.host.shortName);
    final profile = ref.read(identityProvider).profile;
    final (headline, body) = switch (screen) {
      SoldOutScreen() => ('This one filled up before you got here.', null),
      ExpiredScreen()
          when a.status == PublicActivityStatusEnum.started && view.status != InviteViewStatusEnum.expired =>
        (
          'This activity has started.',
          'Bookings closed at ${formatTime(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}. $host has more coming up.',
        ),
      ExpiredScreen() => ('This invite expired when the activity started.', 'Bookings close at the start time.'),
      PausedScreen() => ('This link is paused.', '$inviter can send you a new invite, or pick another date below.'),
      ClaimedScreen(own: true) => (
        profile == null ? 'You’re already going.' : 'You’re already going, ${firstName(profile.displayName)}.',
        'You claimed this invite on this phone.',
      ),
      _ => (
        'This invite has already been claimed.',
        'A vouch invite is for one person. If it was meant for you, ask $inviter for a new one. If you claimed it on another phone, continue with the same phone number or email to see your booking.',
      ),
    };

    final steps = <NextStep>[
      if (screen is SoldOutScreen)
        NextStep(
          icon: 'share',
          title: 'Tell $inviter',
          meta: 'Let them know it filled up',
          // The approved prefilled reply (S6 §12 Q3).
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  '${a.title} on ${formatDay(a.startsAt, a.timezone)} filled up before I could claim. Let’s find another date?',
            ),
          ),
        ),
      if (screen is ExpiredScreen && view.status == InviteViewStatusEnum.expired)
        NextStep(
          icon: 'host',
          title: 'See $inviter’s profile',
          meta: view.inviter.shortName,
          onTap: () => context.push('/users/${view.inviter.id}'),
        ),
      if (screen is ClaimedScreen && !(screen as ClaimedScreen).own) ...[
        NextStep(
          icon: 'share',
          title: 'Ask $inviter for a new invite',
          meta: 'Opens your share sheet',
          // New copy, not in the deck (owner review, S7 PLANNING change log).
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  'Hi $inviter, the invite for ${a.title} on ${formatDay(a.startsAt, a.timezone)} was already claimed. Could you send me a new one?',
            ),
          ),
        ),
        NextStep(
          icon: 'phone',
          title: 'Continue with your phone or email',
          meta: 'See bookings from another device',
          onTap: () => context.push('/signin?next=/me/plans'),
        ),
      ],
    ];
    final booking = a.viewer?.booking;
    final more = next;

    return ScreenBody(
      children: [
        if (screen is SoldOutScreen)
          HeroPhoto(url: a.photoUrl, dimmed: true, aspectRatio: 16 / 9, badge: const SpotsBadge(spots: 0)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${a.title} · ${formatDay(a.startsAt, a.timezone)}',
              style: VelioText.body.copyWith(color: VelioColors.muted),
            ),
            const SizedBox(height: VelioSpace.s2),
            Semantics(header: true, child: Text(headline, style: VelioText.title)),
            if (body != null) ...[
              const SizedBox(height: VelioSpace.s2),
              Text(body, style: VelioText.body.copyWith(color: VelioColors.muted)),
            ],
          ],
        ),
        if (screen is SoldOutScreen) AvatarStack(people: going(a.members), total: a.members.count),
        if (screen is ClaimedScreen && (screen as ClaimedScreen).own && booking != null)
          VButton('Open the plan', block: true, onPressed: () => context.push('/plans/${booking.planId}')),
        if (steps.isNotEmpty) ...[const SectionHeading('What you can do'), NextStepList(steps)],
        if (more != null && more.hostOtherDates.isNotEmpty) ...[
          SectionHeading('$host’s other dates'),
          NextStepList([for (final c in more.hostOtherDates) cardStep(context, c)]),
        ],
        if (more != null && more.moreInCommunity.isNotEmpty) ...[
          SectionHeading('More in ${a.community.name}'),
          NextStepList([for (final c in more.moreInCommunity) cardStep(context, c)]),
        ],
      ],
    );
  }
}

/// Activity pages are web-only (PRD W1), so these open the browser.
NextStep cardStep(BuildContext context, ActivityCard c) => NextStep(
  title: c.title,
  meta: '${formatWhen(c.startsAt, c.timezone)} · ${spotsLabel(c.spotsLeft)}',
  photoUrl: c.photoUrl,
  onTap: () => openInBrowser('/activities/${c.id}'),
);
