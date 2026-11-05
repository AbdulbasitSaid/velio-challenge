// B1's action for each state (S7b FR-004, FR-005): host, already going, removed, started, paused, sold
// out (on the page or mid-attempt), offline, and Book with its retry.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';
import '../bloc/activity_bloc.dart';
import 'more_to_do.dart';

class ActivityAction extends StatelessWidget {
  const ActivityAction({super.key, required this.state, required this.online});
  final ActivityState state;
  final bool online;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children(context));

  /// The action's parts, top to bottom.
  List<Widget> children(BuildContext context) {
    const gap = SizedBox(height: VelioSpace.s3);
    final a = state.activity!;
    final booking = state.booking;
    if (state.isHost) {
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
    if (state.going) {
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
    final more = MoreToDo(activity: a, next: state.next);
    if (state.removed) {
      return [
        const VBanner(
          title: 'The host removed your booking for this activity.',
          body: 'Your spot was released. You can still book another date.',
        ),
        more,
      ];
    }
    if (state.started) {
      return [
        VBanner(
          title: 'This activity has started.',
          body: 'Bookings closed at ${formatTime(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}.',
        ),
        more,
        gap,
        const VButton('Bookings closed', block: true),
      ];
    }
    if (state.paused) {
      return const [
        VBanner(
          title: 'Bookings are paused for this activity.',
          body: 'Nothing has changed for people already going. Check back soon.',
        ),
        gap,
        VButton('Bookings paused', block: true),
      ];
    }
    if (state.attempt == BookingAttempt.soldOut) {
      return [
        const VBanner(
          tone: BannerTone.error,
          title: 'Someone just took the last spot.',
          body: 'We didn’t book or charge you.',
        ),
        more,
      ];
    }
    if (state.soldOut) {
      return [const VButton('Sold out', block: true), more];
    }
    final attempt = state.attempt;
    return [
      if (attempt == BookingAttempt.error) ...[
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
          attempt == BookingAttempt.booking
              ? 'Booking…'
              : (attempt == BookingAttempt.error ? 'Try again' : 'Book a spot'),
          block: true,
          loading: attempt == BookingAttempt.booking,
          onPressed: () => context.read<ActivityBloc>().add(const ActivityBookPressed()),
        ),
    ];
  }
}
