// H2 create and edit (S7b FR-007–FR-010; web activity-form.tsx; PRD A1, A4, Q2, Q13). Copy-deck
// validation with a summary, a preview card, the location picker, and the photo uploaded straight to
// the bucket. After the first booking, date, time, zone and place show locked; the API's
// `location_locked` and `capacity_below_bookings` land on their fields. Price and community are set
// once: the API has no edit for them.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/host_form.dart';
import '../core/photo.dart';
import '../core/providers.dart';
import '../ui/art.dart';
import '../ui/cards.dart';
import '../ui/components.dart';
import '../ui/location.dart';
import '../ui/picker.dart';
import 'errors.dart';
import 'invite.dart' show placeOf;

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key, this.id, this.published = false});

  /// Null when creating.
  final String? id;

  /// Straight after publishing (`?published=1`).
  final bool published;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<ActivityFormScreen> {
  List<Community>? _communities;
  PublicActivity? _activity;
  ApiException? _error;
  late HostForm _form;
  late HostForm _baseline;
  Uint8List? _preview;
  bool _photoBusy = false;
  String? _photoFailed;
  bool _showErrors = false;
  FormErrors _apiErrors = {};
  String? _banner;
  bool _saving = false;
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _meeting = TextEditingController();
  final _price = TextEditingController();
  final _capacity = TextEditingController();

  bool get _editing => widget.id != null;
  int get _booked => _activity?.members.count ?? 0;
  bool get _locked => _booked > 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _meeting, _price, _capacity]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ref.read(apiProvider);
    try {
      final communities = (await api.communities()).communities;
      PublicActivity? activity;
      if (widget.id != null) {
        activity = await api.activity(widget.id!);
        // Anyone but the host gets X4's not-found (S5 SEC-008).
        if (!(activity.viewer?.isHost ?? false)) throw const ApiException(status: 404, code: 'not_found');
      }
      if (!mounted) return;
      final slug = communities.isEmpty ? 'explore-kenya' : communities.first.slug;
      final form = activity != null
          ? formFromActivity(activity)
          : HostForm(communitySlug: slug, timezone: communityZone(slug));
      setState(() {
        _communities = communities;
        _activity = activity;
        _form = form;
        _baseline = form;
        _error = null;
      });
      _title.text = form.title;
      _description.text = form.description;
      _meeting.text = form.meetingPoint;
      _price.text = form.price;
      _capacity.text = '${form.capacity ?? ''}';
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String get _currency => _activity?.currency ?? communityCurrency(_form.communitySlug);

  FormErrors _validate(DateTime now) =>
      validate(_form, editing: _editing, locked: _locked, booked: _booked, currency: _currency, now: now);

  void _set(HostForm next, Set<Field> touched) => setState(() {
    _form = next;
    if (_apiErrors.isEmpty) return;
    final e = {..._apiErrors};
    for (final f in touched) {
      e.remove(f);
    }
    if (touched.contains(Field.location) || touched.contains(Field.date)) {
      e
        ..remove(Field.location)
        ..remove(Field.date);
    }
    _apiErrors = e;
  });

  Future<void> _pickPhoto() async {
    final Uint8List? picked;
    try {
      picked = await ref.read(photoPickerProvider)();
    } catch (_) {
      setState(() => _photoFailed = 'We couldn’t read that photo. Try a JPG or PNG.');
      return;
    }
    if (picked == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _photoFailed = null;
    });
    try {
      final up = await ref.read(photoUploaderProvider).upload(picked);
      if (!mounted) return;
      setState(() => _preview = up.preview);
      _set(_form.copyWith(photoKey: () => up.key), {Field.photo});
    } on PhotoError catch (e) {
      if (mounted) {
        setState(
          () => _photoFailed = e.unreadable
              ? 'We couldn’t read that photo. Try a JPG or PNG.'
              : 'We couldn’t upload the photo. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _banner = null);
    if (_validate(ref.read(clockProvider)()).isNotEmpty) {
      setState(() => _showErrors = true);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    setState(() => _saving = true);
    final api = ref.read(apiProvider);
    try {
      if (!_editing) {
        final id = await api.createActivity(createBody(_form));
        if (mounted) context.pushReplacement('/host/$id/edit?published=1');
        return;
      }
      final patch = patchBody(_form, _baseline, locked: _locked);
      if (patch.isNotEmpty) await api.patchActivity(widget.id!, patch);
      if (!mounted) return;
      setState(() {
        _baseline = _form;
        _showErrors = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved')));
    } catch (err) {
      if (!mounted) return;
      setState(() => _saving = false);
      switch (saveFailure(err)) {
        case BannerFailure(:final text):
          setState(() => _banner = text);
        case FieldFailure(:final fields, :final refresh):
          setState(() => _apiErrors = fields);
          if (refresh) _reloadActivity();
      }
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// After `location_locked` or `capacity_below_bookings`: the booking count changed.
  Future<void> _reloadActivity() async {
    try {
      final a = await ref.read(apiProvider).activity(widget.id!);
      if (mounted) setState(() => _activity = a);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final current = DateTime.tryParse(_form.date);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(DateTime(now.year, now.month, now.day)) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    final date = '${picked.year.toString().padLeft(4, '0')}-${_two(picked.month)}-${_two(picked.day)}';
    _set(_form.copyWith(date: date), {Field.date});
  }

  Future<void> _pickTime() async {
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(_form.time);
    final picked = await showTimePicker(
      context: context,
      initialTime: m == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: int.parse(m[1]!), minute: int.parse(m[2]!)),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return;
    _set(_form.copyWith(time: '${_two(picked.hour)}:${_two(picked.minute)}'), {Field.time});
  }

  Future<void> _pickZone() async {
    final zone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VelioColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (_) => const _ZoneSheet(),
    );
    if (zone != null) _set(_form.copyWith(timezone: zone), {Field.timezone});
  }

  Future<void> _pickCommunity() async {
    final slug = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VelioColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in _communities ?? const <Community>[])
              ListTile(
                title: Text(c.name, style: VelioText.bodyStrong),
                selected: c.slug == _form.communitySlug,
                onTap: () => Navigator.pop(sheet, c.slug),
              ),
          ],
        ),
      ),
    );
    if (slug == null || slug == _form.communitySlug) return;
    // A new activity follows its community's zone until the host picks one (S7b PLANNING §12 D3).
    final followZone = _form.timezone == communityZone(_form.communitySlug);
    _set(_form.copyWith(communitySlug: slug, timezone: followZone ? communityZone(slug) : null), const {});
  }

  @override
  Widget build(BuildContext context) {
    final err = _error;
    if (!ref.watch(identityProvider).signedIn) {
      return Scaffold(
        appBar: VAppBar(leading: _back(context), title: 'Host'),
        body: ScreenBody(
          children: [
            const EmptyState(
              icon: 'host',
              title: 'Host on Velio',
              body: 'Continue with your phone or email to create activities.',
            ),
            VButton(
              'Continue with your phone or email',
              block: true,
              onPressed: () => context.push('/signin?next=/host'),
            ),
          ],
        ),
      );
    }
    if (_communities == null) {
      if (err != null) {
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
      return Scaffold(
        appBar: VAppBar(leading: _back(context), title: _editing ? 'Edit activity' : 'Create an activity'),
        body: const ScreenBody(
          children: [
            Skeleton(height: 180, radius: VelioRadius.card),
            Skeleton(height: 52, radius: VelioRadius.field),
            Skeleton(height: 52, radius: VelioRadius.field),
          ],
        ),
      );
    }
    return _formView(context);
  }

  Widget _back(BuildContext context) => VIconButton(
    'back',
    label: 'My activities',
    onPressed: () => context.canPop() ? context.pop() : context.go('/host'),
  );

  Widget _formView(BuildContext context) {
    final validation = _showErrors ? _validate(ref.read(clockProvider)()) : const <Field, String>{};
    final errors = <Field, String>{...validation, ..._apiErrors, Field.photo: ?_photoFailed};
    final activity = _activity;
    final community = _communities!.where((c) => c.slug == _form.communitySlug).firstOrNull;
    final iso = zonedToIso(_form.date, _form.time, _form.timezone);
    final priceMinor = parsePrice(_form.price, _currency);
    final title = _baseline.title.isEmpty ? 'your activity' : _baseline.title;
    final pageTitle = widget.published ? title : (_editing ? 'Edit $title' : 'Create an activity');
    final me = ref.read(identityProvider).profile;
    final host = activity?.host.shortName ?? (me == null ? '' : shortName(me.displayName));

    return Scaffold(
      appBar: VAppBar(leading: _back(context), title: _editing ? 'Edit activity' : 'Create activity'),
      body: SafeArea(
        top: false,
        child: ScreenBody(
          controller: _scroll,
          children: [
            Semantics(header: true, child: Text(pageTitle, style: VelioText.title)),
            if (widget.published && activity != null)
              Container(
                padding: const EdgeInsets.all(VelioSpace.s4),
                decoration: BoxDecoration(
                  color: VelioColors.lime,
                  borderRadius: BorderRadius.circular(VelioRadius.card),
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const VIcon('check'),
                          const SizedBox(width: VelioSpace.s3),
                          Expanded(
                            child: Text(
                              'Published. $title is live in ${activity.community.name}.',
                              style: VelioText.bodyStrong.copyWith(color: VelioColors.forest),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VelioSpace.s3),
                      VButton(
                        'Open live attendance',
                        variant: ButtonVariant.secondary,
                        small: true,
                        block: true,
                        onPressed: () => context.push('/host/${activity.id}/attendance'),
                      ),
                      VButton(
                        'View the page',
                        variant: ButtonVariant.quiet,
                        small: true,
                        block: true,
                        onPressed: () => context.push('/activities/${activity.id}'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_locked)
              VBanner(
                title: lockedNote,
                body:
                    '${_booked == 1 ? '1 person is' : '$_booked people are'} going. You can still change the title, description, photo and number of spots.',
              ),
            if (validation.isNotEmpty)
              VBanner(
                tone: BannerTone.error,
                title: summaryTitle(validation.length, editing: _editing),
                body: 'They’re marked below.',
              ),
            if (_banner != null)
              VBanner(
                tone: BannerTone.error,
                title: _editing ? 'We couldn’t save your changes.' : 'We couldn’t publish this.',
                body: _banner,
              ),
            const SectionHeading('The basics'),
            _photo(errors[Field.photo], activity?.photoUrl),
            VTextField(
              label: 'Title',
              controller: _title,
              placeholder: 'What are people signing up for?',
              maxLength: 200,
              error: errors[Field.title],
              onChanged: (v) => _set(_form.copyWith(title: v), {Field.title}),
            ),
            VTextField(
              label: 'Description',
              controller: _description,
              placeholder: 'What happens, what to bring, who it suits',
              maxLength: 5000,
              multiline: true,
              onChanged: (v) => _set(_form.copyWith(description: v), const {}),
            ),
            _PickerField(
              label: 'Community',
              value: community?.name ?? _form.communitySlug,
              onTap: _editing ? null : _pickCommunity,
            ),
            const SectionHeading('When'),
            _PickerField(
              label: 'Date',
              value: _form.date.isEmpty ? null : formatDay(DateTime.parse('${_form.date}T12:00:00Z'), 'UTC'),
              placeholder: 'Pick a date',
              error: errors[Field.date],
              onTap: _locked ? null : _pickDate,
            ),
            _PickerField(
              label: 'Start time',
              value: _form.time.isEmpty ? null : _form.time,
              placeholder: 'Pick a time',
              error: errors[Field.time],
              onTap: _locked ? null : _pickTime,
            ),
            _PickerField(
              label: 'Time zone',
              value: _form.timezone,
              help: 'Guests see times in this zone',
              error: errors[Field.timezone],
              onTap: _locked ? null : _pickZone,
            ),
            const SectionHeading('Where'),
            if (_locked && activity != null) ...[
              LocationBlock(place: placeOf(activity.location)),
              Row(
                children: [
                  const VIcon('lock', size: 18),
                  const SizedBox(width: VelioSpace.s2),
                  Expanded(
                    child: Text(
                      'Location is locked because people have booked.',
                      style: VelioText.caption.copyWith(color: VelioColors.muted),
                    ),
                  ),
                ],
              ),
              if (errors[Field.location] != null)
                Text(errors[Field.location]!, style: VelioText.caption.copyWith(color: VelioColors.danger)),
            ] else ...[
              LocationPicker(
                value: _form.location,
                center: communityCenter(_form.communitySlug),
                errors: errors,
                onChanged: (v) =>
                    _set(_form.copyWith(location: () => v), {Field.location, Field.venueName, Field.addressText}),
              ),
              VTextField(
                label: 'Meeting point (optional)',
                controller: _meeting,
                placeholder: 'Where exactly to find you',
                maxLength: meetingPointMax,
                help: '${_meeting.text.length}/$meetingPointMax',
                onChanged: (v) => _set(_form.copyWith(meetingPoint: v), const {}),
              ),
            ],
            const SectionHeading('Price and spots'),
            VTextField(
              label: 'Price per person ($_currency)',
              controller: _price,
              enabled: !_editing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              help: 'Guests pay you on the day. Velio takes no payment.',
              error: errors[Field.price],
              onChanged: (v) => _set(_form.copyWith(price: v), {Field.price}),
            ),
            _Spots(
              controller: _capacity,
              value: _form.capacity,
              floor: _booked > 1 ? _booked : 1,
              booked: _booked,
              error: errors[Field.capacity],
              onChanged: (v) {
                _capacity.text = '${v ?? ''}';
                _set(_form.copyWith(capacity: () => v), {Field.capacity});
              },
              onTyped: (v) => _set(_form.copyWith(capacity: () => v), {Field.capacity}),
            ),
            Text(
              'PREVIEW',
              style: VelioText.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.72,
                color: VelioColors.muted,
              ),
            ),
            ActivityTile(
              title: _form.title.trim().isEmpty ? 'Your activity title' : _form.title.trim(),
              meta:
                  '${iso == null ? 'Date and time' : '${formatWhen(DateTime.parse(iso), _form.timezone)} ${zoneLabel(_form.timezone)}'} · ${_form.location?.venueName.trim().isNotEmpty ?? false ? _form.location!.venueName.trim() : 'Location'}',
              photoUrl: activity?.photoUrl,
              photoBytes: _preview,
              chip: community?.name,
              spots: ((_form.capacity ?? 0) - _booked).clamp(0, capacityMax),
              lines: [
                if (priceMinor != null) '${formatMoney(priceMinor, _currency)} · pay the host on the day',
                if (host.isNotEmpty) 'Hosted by $host',
              ],
            ),
            VButton(
              _editing ? 'Save changes' : 'Publish',
              block: true,
              loading: _saving,
              onPressed: _photoBusy ? null : _submit,
            ),
            if (!_locked)
              Text(
                'Once someone books, date, time and place lock. Check them before you publish.',
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photo(String? error, String? url) {
    final has = _preview != null || url != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (has)
          ClipRRect(
            borderRadius: BorderRadius.circular(VelioRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_preview != null)
                    Image.memory(_preview!, fit: BoxFit.cover, gaplessPlayback: true)
                  else
                    Photo(url: url),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: VelioColors.surface,
                      shape: const StadiumBorder(),
                      child: VButton(
                        'Change photo',
                        small: true,
                        variant: ButtonVariant.quiet,
                        loading: _photoBusy,
                        onPressed: _pickPhoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s5, vertical: 28),
            decoration: BoxDecoration(
              color: VelioColors.surface,
              borderRadius: BorderRadius.circular(VelioRadius.card),
              border: Border.all(color: error != null ? VelioColors.danger : VelioColors.fieldBorder, width: 2),
            ),
            child: Column(
              children: [
                Text('Add one photo', style: VelioText.bodyStrong),
                const SizedBox(height: VelioSpace.s2),
                Text(
                  'It leads your activity page and every invite link.',
                  textAlign: TextAlign.center,
                  style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
                ),
                const SizedBox(height: VelioSpace.s3),
                VButton(
                  _photoBusy ? 'Uploading…' : 'Choose a photo',
                  variant: ButtonVariant.secondary,
                  small: true,
                  loading: _photoBusy,
                  onPressed: _pickPhoto,
                ),
              ],
            ),
          ),
        if (error != null) ...[const SizedBox(height: 6), _FieldError(error)],
      ],
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: VIcon('alert', size: 16, color: VelioColors.danger),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: VelioText.caption.copyWith(color: VelioColors.danger)),
        ),
      ],
    ),
  );
}

/// A field that opens a picker: date, time, zone, community. Read-only when [onTap] is null.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, this.value, this.placeholder, this.help, this.error, this.onTap});
  final String label;
  final String? value;
  final String? placeholder;
  final String? help;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 18 / 14)),
        const SizedBox(height: 6),
        Semantics(
          button: enabled,
          label: '$label, ${value ?? placeholder ?? ''}',
          excludeSemantics: true,
          child: Material(
            color: enabled ? VelioColors.surface : VelioColors.disabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VelioRadius.field),
              side: BorderSide(
                color: error != null ? VelioColors.danger : (enabled ? VelioColors.fieldBorder : VelioColors.disabled),
                width: error != null ? 2 : 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(VelioRadius.field),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value ?? placeholder ?? '',
                          style: VelioText.body.copyWith(
                            fontSize: 16,
                            color: value == null ? VelioColors.muted : VelioColors.ink,
                          ),
                        ),
                      ),
                      VIcon(enabled ? 'chevron' : 'lock', size: 18, color: VelioColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          _FieldError(error!),
        ] else if (help != null) ...[
          const SizedBox(height: 6),
          Text(help!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
        ],
      ],
    );
  }
}

/// "Total spots" with − and + (never below the people booked).
class _Spots extends StatelessWidget {
  const _Spots({
    required this.controller,
    required this.value,
    required this.floor,
    required this.booked,
    required this.error,
    required this.onChanged,
    required this.onTyped,
  });
  final TextEditingController controller;
  final int? value;
  final int floor;
  final int booked;
  final String? error;
  final ValueChanged<int?> onChanged;
  final ValueChanged<int?> onTyped;

  @override
  Widget build(BuildContext context) {
    final v = value;
    Widget step(String icon, String label, VoidCallback? onTap) => Semantics(
      button: true,
      label: label,
      child: Material(
        color: VelioColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: onTap == null ? VelioColors.disabled : VelioColors.fieldBorder, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: VelioSize.touchMin,
            child: Center(child: VIcon(icon, color: onTap == null ? VelioColors.muted : VelioColors.forest)),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total spots', style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 18 / 14)),
        const SizedBox(height: 6),
        Row(
          children: [
            step(
              'minus',
              'One fewer spot',
              v != null && v > floor ? () => onChanged(v - 1 < floor ? floor : v - 1) : null,
            ),
            const SizedBox(width: VelioSpace.s2),
            SizedBox(
              width: 96,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: VelioText.bodyStrong.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VelioColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: VelioSpace.s2, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VelioRadius.field),
                    borderSide: BorderSide(
                      color: error != null ? VelioColors.danger : VelioColors.fieldBorder,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VelioRadius.field),
                    borderSide: const BorderSide(color: VelioColors.forest, width: 2),
                  ),
                ),
                onChanged: (raw) => onTyped(int.tryParse(raw)),
              ),
            ),
            const SizedBox(width: VelioSpace.s2),
            step(
              'plus',
              'One more spot',
              v != null && v >= capacityMax
                  ? null
                  : () => onChanged(v == null ? floor : (v + 1 < floor ? floor : v + 1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (error != null)
          _FieldError(error!)
        else
          Text(spotsHelp(booked), style: VelioText.caption.copyWith(color: VelioColors.muted)),
      ],
    );
  }
}

class _ZoneSheet extends StatefulWidget {
  const _ZoneSheet();
  @override
  State<_ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends State<_ZoneSheet> {
  final _all = timeZoneNames();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase().replaceAll(' ', '_');
    final shown = q.isEmpty ? _all : _all.where((z) => z.toLowerCase().contains(q)).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s5, VelioSpace.s5, VelioSpace.s2),
              child: VTextField(
                label: 'Time zone',
                placeholder: 'Search, e.g. Nairobi',
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(shown[i], style: VelioText.body),
                  onTap: () => Navigator.pop(context, shown[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
