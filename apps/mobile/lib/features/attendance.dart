// H1 live attendance (S7b FR-011, FR-012; web attendance-live.tsx; PRD H1, H2, D3, D5). The screen
// listens to `activity:<id>` for spots and `host:<id>` for bookings; an `attendance` event carries
// only the ID, so the list is fetched again (rule 5). Before the start each row offers Remove (always
// confirmed first); from the start, attended or no-show, where the latest mark wins. The host sees
// names, refs and sources, never contacts (SEC-002).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/attendance.dart';
import '../core/format.dart';
import '../core/live.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../core/realtime.dart';
import '../ui/cards.dart';
import '../ui/components.dart';
import 'errors.dart';

const privacyNote = 'You see names and how people found you. Phone numbers, emails and invite notes stay private.';

/// setTimeout's ceiling on the web; a start further out is caught by the next load instead.
const _maxTimer = Duration(milliseconds: 2147483647);

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceState();
}

class _AttendanceState extends ConsumerState<AttendanceScreen> {
  Attendance? _data;
  PublicActivity? _activity;
  ApiException? _error;
  LiveSpots? _live;
  bool _started = false;
  Timer? _startTimer;
  final _query = TextEditingController();
  final _seen = <String>{};
  final _arrived = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _live?.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ref.read(apiProvider);
    try {
      final (data, activity) = await (api.attendance(widget.id), api.activity(widget.id)).wait;
      if (!mounted) return;
      _apply(data);
      setState(() {
        _activity = activity;
        _error = null;
      });
      _watchStart(data.activity);
      _live ??= LiveSpots(
        realtime: ref.read(realtimeProvider),
        activityId: widget.id,
        spotsLeft: data.activity.spotsLeft,
        version: data.activity.version,
        refresh: _refresh,
        extraTopics: ['host:${widget.id}'],
        onAttendance: () => _refetch(),
        view: View.maybeOf(context),
      )..addListener(() => mounted ? setState(() {}) : null);
    } on ParallelWaitError<(Attendance?, PublicActivity?), (AsyncError?, AsyncError?)> catch (e) {
      final err = e.errors.$1?.error ?? e.errors.$2?.error;
      if (mounted) setState(() => _error = ApiException.from(err ?? 'unknown'));
    }
  }

  void _apply(Attendance fresh) {
    final first = _data == null;
    for (final a in fresh.attendees) {
      if (_seen.add(a.bookingId) && !first) _arrived.add(a.bookingId);
    }
    setState(() => _data = fresh);
  }

  Future<void> _refresh() async {
    final fresh = await ref.read(apiProvider).attendance(widget.id);
    if (!mounted) return;
    _apply(fresh);
    _live?.apply(fresh.activity.spotsLeft, fresh.activity.version);
  }

  Future<void> _refetch() async {
    try {
      await _refresh();
    } catch (_) {}
  }

  /// Marking opens at the start (PRD H2): the screen flips then, and fetches once so marks made
  /// elsewhere show.
  void _watchStart(AttendanceActivity a) {
    if (_started || _startTimer != null) return;
    if (a.started) {
      _started = true;
      return;
    }
    final wait = a.startsAt.difference(ref.read(clockProvider)());
    if (wait > _maxTimer) return;
    _startTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (!mounted) return;
      setState(() => _started = true);
      _refetch();
    });
  }

  void _flash(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _put(Attendee m) => setState(() {
    final d = _data!;
    _data = Attendance(
      activity: d.activity,
      attendees: [for (final x in d.attendees) x.bookingId == m.bookingId ? m : x],
    );
  });

  Future<void> _mark(Attendee a, Mark next) async {
    final mark = next == Mark.attended ? AttendanceMark.attended : AttendanceMark.noShow;
    if (a.mark == mark) return;
    _put(Attendee.fromJson({...a.toJson(), 'mark': mark.value}));
    try {
      _put(await ref.read(apiProvider).mark(a.bookingId, mark));
    } catch (err) {
      if (!mounted) return;
      _put(a);
      _flash(markFailure(err, a.person.displayName));
      if (ApiException.from(err).code == 'booking_removed') _refetch();
    }
  }

  Future<void> _remove(Attendee a) async {
    final name = a.person.displayName;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: VelioColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s5, VelioSpace.s5, VelioSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Remove $name?', style: VelioText.heading.copyWith(fontSize: 20))),
              const SizedBox(height: VelioSpace.s2),
              Text(
                'Their spot opens to whoever books next, and they’ll see that you removed them.',
                style: VelioText.body.copyWith(color: VelioColors.muted),
              ),
              const SizedBox(height: VelioSpace.s4),
              _DangerButton('Remove ${firstName(name)}', onPressed: () => Navigator.pop(sheet, true)),
              const SizedBox(height: VelioSpace.s2),
              VButton('Keep', variant: ButtonVariant.quiet, block: true, onPressed: () => Navigator.pop(sheet, false)),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(apiProvider).removeBooking(a.bookingId);
      await _refetch();
      _flash('${firstName(name)} removed. Their spot is open again.');
    } catch (err) {
      _flash(
        ApiException.from(err).network
            ? 'You’re offline. Reconnect to remove a guest.'
            : 'We couldn’t remove ${firstName(name)}. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final err = _error;
    final data = _data;
    final activity = _activity;
    if ((data == null || activity == null) && err != null) {
      final notFound = [400, 403, 404].contains(err.status);
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
          label: 'My activities',
          onPressed: () => context.canPop() ? context.pop() : context.go('/host'),
        ),
        title: 'Attendance',
        trailing: data == null
            ? null
            : LivePill(
                status: !online ? LiveStatus.offline : (reconnecting ? LiveStatus.reconnecting : LiveStatus.live),
              ),
      ),
      body: SafeArea(
        top: false,
        child: data == null || activity == null
            ? const ScreenBody(
                gap: VelioSpace.s4,
                children: [
                  Skeleton(height: 34, width: 240),
                  Skeleton(height: 72, radius: VelioRadius.hero),
                  Skeleton(height: 220, radius: VelioRadius.card),
                ],
              )
            : RefreshIndicator(onRefresh: _refetch, child: _body(context, data, activity, online, reconnecting)),
      ),
    );
  }

  Widget _body(BuildContext context, Attendance data, PublicActivity activity, bool online, bool reconnecting) {
    final live = _live;
    final tz = activity.timezone;
    final spots = live?.spotsLeft ?? data.activity.spotsLeft;
    final spotsState = !online || reconnecting
        ? SpotsState.stale
        : (live?.changed ?? false)
        ? SpotsState.changed
        : SpotsState.live;
    final stats = attendanceStats(data);
    final empty = data.attendees.isEmpty;
    final rows = orderAttendees(data.attendees, started: _started).where((a) => matchesGuest(a, _query.text)).toList();

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
                    Text(_started ? 'Marked' : 'Booked', style: VelioText.caption.copyWith(color: VelioColors.muted)),
                    Text(
                      _started ? '${stats.marked} of ${stats.booked}' : '${stats.booked} of ${stats.capacity}',
                      style: VelioText.heading.copyWith(fontSize: 24, height: 30 / 24),
                    ),
                  ],
                ),
              ),
              SpotsBadge(spots: spots, state: spotsState),
            ],
          ),
        ),
        if (_started && !empty)
          const VBanner(
            title: 'The activity has started.',
            body: 'Mark who came. It’s how Velio counts the plans that actually happen.',
          ),
        if (!empty)
          VTextField(
            label: 'Find a guest',
            controller: _query,
            placeholder: 'Name or booking ref',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: VelioSpace.s3,
          children: [
            SectionHeading(_started ? 'Who came?' : 'Going'),
            if (!empty)
              Text(
                _started ? 'Tap to mark' : 'Newest first',
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
          ],
        ),
        if (empty)
          EmptyState(
            icon: 'people',
            title: 'No bookings yet',
            body: _started
                ? 'Nobody booked this activity.'
                : 'This page updates by itself the moment someone books. Bookings close at ${formatTime(activity.startsAt, tz)} ${zoneLabel(tz)} on ${formatDay(activity.startsAt, tz)}.',
          )
        else if (rows.isEmpty)
          Text('No guest matches “${_query.text.trim()}”.', style: VelioText.body.copyWith(color: VelioColors.muted))
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
                        : _arrived.contains(a.bookingId)
                        ? 'Booked just now'
                        : 'Booked ${formatDay(a.bookedAt, tz)}'}',
                source: attendeeSource(a),
                sourceTone: switch (a.source_) {
                  AttendeeSource_Enum.vouch => ChipTone.lime,
                  AttendeeSource_Enum.public => ChipTone.sky,
                  AttendeeSource_Enum.direct => ChipTone.neutral,
                },
                after: _started,
                mark: switch (a.mark) {
                  AttendanceMark.attended => Mark.attended,
                  AttendanceMark.noShow => Mark.noShow,
                  null => null,
                },
                isNew: _arrived.contains(a.bookingId) && a.status == AttendeeStatusEnum.confirmed,
                removed: a.status == AttendeeStatusEnum.removed,
                onRemove: () => _remove(a),
                onMark: (m) => _mark(a, m),
              ),
          ]),
        if (!empty) Text(privacyNote, style: VelioText.caption.copyWith(color: VelioColors.muted)),
        if (!_started)
          VButton(
            'Edit activity',
            variant: ButtonVariant.secondary,
            block: true,
            onPressed: () async {
              await context.push('/host/${widget.id}/edit');
              if (mounted) _load();
            },
          ),
      ],
    );
  }
}

/// The destructive confirm (`host.remove.confirm`).
class _DangerButton extends StatelessWidget {
  const _DangerButton(this.label, {required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: VelioColors.danger,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VelioSize.buttonHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s6, vertical: VelioSpace.s2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: VelioText.button.copyWith(color: VelioColors.surface),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
