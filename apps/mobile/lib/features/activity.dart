// B1 activity page (S7b FR-004, FR-005; web activity-live.tsx): live spots under the six realtime
// rules, who's going refetched after a spots change, and Book with one Idempotency-Key per attempt:
// "Booking…" at once, success only when the API confirms, then "You're in" with a haptic (PRD M3).
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/booking.dart';
import '../core/format.dart';
import '../core/live.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../core/realtime.dart';
import '../ui/art.dart';
import '../ui/cards.dart';
import '../ui/components.dart';
import '../ui/location.dart';
import 'claim.dart';
import 'errors.dart';
import 'invite.dart';

enum _Attempt { idle, booking, soldOut, error, started, paused }

final _random = Random();

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityState();
}

class _ActivityState extends ConsumerState<ActivityScreen> {
  PublicActivity? _a;
  PublicActivityMembers? _members;
  ApiException? _error;
  LiveSpots? _live;
  NextSteps? _next;
  Timer? _membersTimer;
  _Attempt _attempt = _Attempt.idle;
  bool _wasSoldOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _membersTimer?.cancel();
    _live?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _fetch();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _fetch() async {
    final a = await ref.read(apiProvider).activity(widget.id);
    if (!mounted) return;
    setState(() {
      _a = a;
      _members = a.members;
      _error = null;
    });
    final live = _live;
    if (live == null) {
      _live = LiveSpots(
        realtime: ref.read(realtimeProvider),
        activityId: a.id,
        spotsLeft: a.spotsLeft,
        version: a.version,
        refresh: _fetch,
        view: View.maybeOf(context),
      )..addListener(_onLive);
      _wasSoldOut = a.spotsLeft <= 0;
    } else {
      live.apply(a.spotsLeft, a.version);
    }
  }

  void _onLive() {
    if (!mounted) return;
    final live = _live!;
    // PRD M3: a distinct haptic as the page lands on sold out.
    final soldOut = live.spotsLeft <= 0;
    if (soldOut && !_wasSoldOut) HapticFeedback.heavyImpact();
    _wasSoldOut = soldOut;
    // A `spots` event carries only the count, so who's going is fetched again. A random 0–2 s delay
    // spreads the refetch when many people watch one activity; a newer change replaces the pending one.
    if (live.changed) {
      _membersTimer?.cancel();
      _membersTimer = Timer(Duration(milliseconds: _random.nextInt(2000)), () async {
        try {
          final fresh = await ref.read(apiProvider).activity(widget.id);
          if (mounted) setState(() => _members = fresh.members);
        } catch (_) {}
      });
    }
    setState(() {});
  }

  Future<void> _loadNext() async {
    if (_next != null) return;
    try {
      final n = await ref.read(apiProvider).nextSteps(widget.id);
      if (mounted) setState(() => _next = n);
    } catch (_) {
      // Next steps are extras (UX FR-007).
    }
  }

  Future<void> _book() async {
    if (_attempt == _Attempt.booking) return;
    final path = '/activities/${widget.id}';
    if (!ref.read(identityProvider).signedIn) {
      await context.push('/signin?next=${Uri.encodeComponent(path)}');
      return;
    }
    setState(() => _attempt = _Attempt.booking);
    final keys = ref.read(attemptKeysProvider);
    try {
      final res = await ref.read(apiProvider).book(widget.id, idempotencyKey: await keys.forBooking(widget.id));
      await keys.clearBooking(widget.id);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _attempt = _Attempt.idle);
      await context.push('/plans/${res.booking.planId}/welcome');
      if (mounted) _load();
    } catch (err) {
      final outcome = bookingOutcome(err);
      if (outcome != BookingOutcome.error) await keys.clearBooking(widget.id);
      if (!mounted) return;
      switch (outcome) {
        case BookingOutcome.signIn:
          setState(() => _attempt = _Attempt.idle);
          await context.push('/signin?next=${Uri.encodeComponent(path)}');
        case BookingOutcome.refresh:
          setState(() => _attempt = _Attempt.idle);
          await _load();
        case BookingOutcome.soldOut:
          HapticFeedback.heavyImpact();
          setState(() => _attempt = _Attempt.soldOut);
        case BookingOutcome.started:
          setState(() => _attempt = _Attempt.started);
        case BookingOutcome.paused:
          setState(() => _attempt = _Attempt.paused);
        case BookingOutcome.error:
          setState(() => _attempt = _Attempt.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Signing in from Book comes back here: the viewer's state changes with it.
    ref.listen(sessionVersionProvider, (_, _) => _load());
    final a = _a;
    final err = _error;
    if (a == null && err != null) {
      final notFound = err.status == 404 || err.status == 400;
      return ErrorScreen(
        kind: notFound ? ErrorKind.notFound : (err.network ? ErrorKind.offline : ErrorKind.server),
        onRetry: notFound
            ? null
            : () {
                setState(() => _error = null);
                _load();
              },
      );
    }
    final online = isOnline(ref);
    final live = _live;
    final reconnecting = live?.status == RealtimeStatus.reconnecting;
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton(
          'back',
          label: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/explore'),
        ),
        title: a?.community.name ?? 'Activity',
        trailing: a == null
            ? null
            : LivePill(
                status: !online ? LiveStatus.offline : (reconnecting ? LiveStatus.reconnecting : LiveStatus.live),
              ),
      ),
      body: SafeArea(
        top: false,
        child: a == null
            ? const _ActivitySkeleton()
            : RefreshIndicator(onRefresh: _load, child: _body(context, a, online, reconnecting)),
      ),
    );
  }

  Widget _body(BuildContext context, PublicActivity a, bool online, bool reconnecting) {
    final live = _live;
    final spots = live?.spotsLeft ?? a.spotsLeft;
    final spotsState = !online || reconnecting
        ? SpotsState.stale
        : (live?.changed ?? false)
        ? SpotsState.changed
        : SpotsState.live;
    final booking = a.viewer?.booking;
    final started = a.status == PublicActivityStatusEnum.started || _attempt == _Attempt.started;
    final paused = a.bookingsPaused || _attempt == _Attempt.paused;
    final soldOut = spots <= 0 || _attempt == _Attempt.soldOut;
    final removed = booking?.status == PublicActivityViewerBookingStatusEnum.removed;
    if (removed || started || (soldOut && booking == null)) _loadNext();
    final members = _members ?? a.members;
    final priceNote = a.priceMinor == 0
        ? 'Free. Velio doesn’t take payment.'
        : '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day. Velio doesn’t take payment.';

    return ScreenBody(
      children: [
        HeroPhoto(
          url: a.photoUrl,
          dimmed: soldOut || started,
          badge: SpotsBadge(spots: spots, state: spotsState),
        ),
        Semantics(
          header: true,
          child: Text(a.title, style: VelioText.display.copyWith(fontSize: 34, height: 38 / 34)),
        ),
        DetailRows([
          DetailRow('calendar', formatWhen(a.startsAt, a.timezone), zoneLabel(a.timezone)),
          DetailRow('pin', a.location.venueName, a.location.addressText),
          DetailRow(
            'price',
            a.priceMinor == 0 ? 'Free' : '${formatMoney(a.priceMinor, a.currency)} · pay the host on the day',
          ),
          DetailRow('people', '${a.capacity} spots in total'),
        ]),
        AvatarStack(people: going(members), total: members.count),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._action(context, a, booking, started: started, paused: paused, soldOut: soldOut, online: online),
            const SizedBox(height: VelioSpace.s3),
            Text(
              priceNote,
              textAlign: TextAlign.center,
              style: VelioText.caption.copyWith(color: VelioColors.muted),
            ),
          ],
        ),
        const Divider(height: 1, thickness: 1, color: VelioColors.line),
        if (a.description.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading('About'),
              const SizedBox(height: VelioSpace.s2),
              Text(a.description, style: VelioText.body),
            ],
          ),
        LocationBlock(place: placeOf(a.location), offline: !online),
        HostCard(
          name: a.host.shortName,
          seed: a.host.avatarSeed,
          community: a.community.name,
          onProfile: () => context.push('/users/${a.host.id}'),
        ),
      ],
    );
  }

  List<Widget> _action(
    BuildContext context,
    PublicActivity a,
    PublicActivityViewerBooking? booking, {
    required bool started,
    required bool paused,
    required bool soldOut,
    required bool online,
  }) {
    const gap = SizedBox(height: VelioSpace.s3);
    if (a.viewer?.isHost ?? false) {
      return [
        Text(
          'You’re the host of this activity.',
          textAlign: TextAlign.center,
          style: VelioText.body.copyWith(color: VelioColors.muted),
        ),
        gap,
        VButton(
          'Open live attendance',
          variant: ButtonVariant.secondary,
          block: true,
          onPressed: () => context.push('/host/${a.id}/attendance'),
        ),
      ];
    }
    if (booking?.status == PublicActivityViewerBookingStatusEnum.confirmed) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s2),
          decoration: BoxDecoration(color: VelioColors.lime, borderRadius: BorderRadius.circular(VelioRadius.card)),
          child: Row(
            children: [
              const VIcon('check'),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('You’re already going', style: VelioText.bodyStrong.copyWith(color: VelioColors.forest)),
                    VButton(
                      'Open plan',
                      variant: ButtonVariant.quiet,
                      small: true,
                      onPressed: () => context.push('/plans/${booking!.planId}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
    }
    final more = _moreToDo(context, a);
    if (booking?.status == PublicActivityViewerBookingStatusEnum.removed) {
      return [
        const VBanner(
          title: 'The host removed your booking for this activity.',
          body: 'Your spot was released. You can still book another date.',
        ),
        ...more,
      ];
    }
    if (started) {
      return [
        VBanner(
          title: 'This activity has started.',
          body: 'Bookings closed at ${formatTime(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}.',
        ),
        ...more,
        gap,
        const VButton('Bookings closed', block: true),
      ];
    }
    if (paused) {
      return const [
        VBanner(
          title: 'Bookings are paused for this activity.',
          body: 'Nothing has changed for people already going. Check back soon.',
        ),
        gap,
        VButton('Bookings paused', block: true),
      ];
    }
    if (_attempt == _Attempt.soldOut) {
      return [
        const VBanner(
          tone: BannerTone.error,
          title: 'Someone just took the last spot.',
          body: 'We didn’t book or charge you.',
        ),
        ...more,
      ];
    }
    if (soldOut) {
      return [const VButton('Sold out', block: true), ...more];
    }
    return [
      if (_attempt == _Attempt.error) ...[
        const VBanner(
          tone: BannerTone.error,
          title: 'We couldn’t confirm your spot. Nothing was booked.',
          body: 'Try again. You won’t be booked twice.',
        ),
        gap,
      ],
      if (!online)
        const VButton('Reconnect to book', block: true)
      else
        VButton(
          _attempt == _Attempt.booking ? 'Booking…' : (_attempt == _Attempt.error ? 'Try again' : 'Book a spot'),
          block: true,
          loading: _attempt == _Attempt.booking,
          onPressed: _book,
        ),
    ];
  }

  /// The web's MoreToDo: the host's other dates and more in the community.
  List<Widget> _moreToDo(BuildContext context, PublicActivity a) {
    final n = _next;
    if (n == null) return const [];
    return [
      if (n.hostOtherDates.isNotEmpty) ...[
        const SizedBox(height: VelioSpace.s4),
        Text('${firstName(a.host.shortName)}’s other dates', style: VelioText.subheading),
        const SizedBox(height: VelioSpace.s2),
        NextStepList([for (final c in n.hostOtherDates) cardStep(context, c)]),
      ],
      if (n.moreInCommunity.isNotEmpty) ...[
        const SizedBox(height: VelioSpace.s4),
        Text('More in ${a.community.name}', style: VelioText.subheading),
        const SizedBox(height: VelioSpace.s2),
        NextStepList([for (final c in n.moreInCommunity) cardStep(context, c)]),
      ],
    ];
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the activity',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 220, radius: VelioRadius.hero),
        Skeleton(height: 34, width: 260),
        Skeleton(height: 120, radius: VelioRadius.card),
        Skeleton(height: 52, radius: VelioRadius.pill),
      ],
    ),
  );
}
