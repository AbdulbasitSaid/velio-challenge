// H1's body: the stat with live spots, the started banner, guest search and the rows.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/attendance.dart';
import '../../domain/format.dart';
import '../../ui/cards.dart';
import '../../ui/components.dart';
import '../bloc/attendance_bloc.dart';
import 'remove_guest_sheet.dart';

const privacyNote = 'You see names and how people found you. Phone numbers, emails and invite notes stay private.';

class AttendanceContent extends StatelessWidget {
  const AttendanceContent({
    super.key,
    required this.id,
    required this.state,
    required this.online,
    required this.query,
  });
  final String id;
  final AttendanceState state;
  final bool online;
  final TextEditingController query;

  Future<void> _remove(BuildContext context, Attendee a) async {
    final bloc = context.read<AttendanceBloc>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: VelioColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (_) => RemoveGuestSheet(name: a.person.displayName),
    );
    if (ok == true) bloc.add(AttendanceRemoveConfirmed(a));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttendanceBloc>();
    final activity = state.activity!;
    final tz = activity.timezone;
    final started = state.started;
    final spotsState = !online || state.reconnecting
        ? SpotsState.stale
        : (state.live?.changed ?? false)
        ? SpotsState.changed
        : SpotsState.live;
    final stats = state.stats;
    final empty = state.empty;
    final rows = state.rows;

    return ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(activity.title, style: VelioText.title)),
            const SizedBox(height: 4),
            Text(
              '${formatWhen(activity.startsAt, tz)} ${zoneLabel(tz)}',
              style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 14),
          decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.hero)),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: VelioSpace.s3,
            runSpacing: VelioSpace.s2,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(started ? 'Marked' : 'Booked', style: VelioText.caption.copyWith(color: VelioColors.muted)),
                    Text(
                      started ? '${stats.marked} of ${stats.booked}' : '${stats.booked} of ${stats.capacity}',
                      style: VelioText.heading.copyWith(fontSize: 24, height: 30 / 24),
                    ),
                  ],
                ),
              ),
              SpotsBadge(spots: state.spotsLeft, state: spotsState),
            ],
          ),
        ),
        if (started && !empty)
          const VBanner(
            title: 'The activity has started.',
            body: 'Mark who came. It’s how Velio counts the plans that actually happen.',
          ),
        if (!empty)
          VTextField(
            label: 'Find a guest',
            controller: query,
            placeholder: 'Name or booking ref',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onChanged: (v) => bloc.add(AttendanceQueryChanged(v)),
          ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: VelioSpace.s3,
          children: [
            SectionHeading(started ? 'Who came?' : 'Going'),
            if (!empty)
              Text(
                started ? 'Tap to mark' : 'Newest first',
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
          ],
        ),
        if (empty)
          EmptyState(
            icon: 'people',
            title: 'No bookings yet',
            body: started
                ? 'Nobody booked this activity.'
                : 'This page updates by itself the moment someone books. Bookings close at ${formatTime(activity.startsAt, tz)} ${zoneLabel(tz)} on ${formatDay(activity.startsAt, tz)}.',
          )
        else if (rows.isEmpty)
          Text('No guest matches “${state.query.trim()}”.', style: VelioText.body.copyWith(color: VelioColors.muted))
        else
          VList([
            for (final a in rows)
              AttendanceRow(
                key: ValueKey(a.bookingId),
                name: a.person.displayName,
                seed: a.person.avatarSeed,
                meta:
                    '${a.ref} · ${a.status == AttendeeStatusEnum.removed
                        ? 'Removed'
                        : state.arrived.contains(a.bookingId)
                        ? 'Booked just now'
                        : 'Booked ${formatDay(a.bookedAt, tz)}'}',
                source: attendeeSource(a),
                sourceTone: switch (a.source_) {
                  AttendeeSource_Enum.vouch => ChipTone.lime,
                  AttendeeSource_Enum.public => ChipTone.sky,
                  AttendeeSource_Enum.direct => ChipTone.neutral,
                },
                after: started,
                mark: switch (a.mark) {
                  AttendanceMark.attended => Mark.attended,
                  AttendanceMark.noShow => Mark.noShow,
                  null => null,
                },
                isNew: state.arrived.contains(a.bookingId) && a.status == AttendeeStatusEnum.confirmed,
                removed: a.status == AttendeeStatusEnum.removed,
                onRemove: () => _remove(context, a),
                onMark: (m) => bloc.add(
                  AttendanceMarkPressed(a, m == Mark.attended ? AttendanceMark.attended : AttendanceMark.noShow),
                ),
              ),
          ]),
        if (!empty) Text(privacyNote, style: VelioText.caption.copyWith(color: VelioColors.muted)),
        if (!started)
          VButton(
            'Edit activity',
            variant: ButtonVariant.secondary,
            block: true,
            onPressed: () async {
              await context.push('/host/$id/edit');
              if (!bloc.isClosed) bloc.add(const AttendanceRequested());
            },
          ),
      ],
    );
  }
}
