// H2's form: the basics, when, where, price and spots, the preview card and Publish or Save.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../domain/format.dart';
import '../../domain/host_form.dart';
import '../../location_picker/location_picker.dart';
import '../../session/bloc/session_bloc.dart';
import '../../ui/activity_display.dart';
import '../../ui/art.dart';
import '../../ui/cards.dart';
import '../../ui/components.dart';
import '../../ui/location.dart';
import '../bloc/activity_form_bloc.dart';
import 'activity_form_back_button.dart';
import 'photo_field.dart';
import 'picker_field.dart';
import 'published_banner.dart';
import 'spots_field.dart';
import 'zone_sheet.dart';

class ActivityFormContent extends StatelessWidget {
  const ActivityFormContent({
    super.key,
    required this.state,
    required this.published,
    required this.scroll,
    required this.title,
    required this.description,
    required this.meeting,
    required this.price,
    required this.capacity,
  });

  final ActivityFormState state;
  final bool published;
  final ScrollController scroll;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController meeting;
  final TextEditingController price;
  final TextEditingController capacity;

  Future<void> _pickDate(BuildContext context) async {
    final bloc = context.read<ActivityFormBloc>();
    final now = context.read<AppConfig>().clock();
    final current = DateTime.tryParse(state.form!.date);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(DateTime(now.year, now.month, now.day)) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) bloc.add(ActivityFormDateChanged(picked));
  }

  Future<void> _pickTime(BuildContext context) async {
    final bloc = context.read<ActivityFormBloc>();
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(state.form!.time);
    final picked = await showTimePicker(
      context: context,
      initialTime: m == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: int.parse(m[1]!), minute: int.parse(m[2]!)),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null) bloc.add(ActivityFormTimeChanged(picked.hour, picked.minute));
  }

  Future<void> _pickZone(BuildContext context) async {
    final bloc = context.read<ActivityFormBloc>();
    final zone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VelioColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (_) => const ZoneSheet(),
    );
    if (zone != null) bloc.add(ActivityFormTimezoneChanged(zone));
  }

  Future<void> _pickCommunity(BuildContext context) async {
    final bloc = context.read<ActivityFormBloc>();
    final slug = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VelioColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in state.communities ?? const <Community>[])
              ListTile(
                title: Text(c.name, style: VelioText.bodyStrong),
                selected: c.slug == state.form!.communitySlug,
                onTap: () => Navigator.pop(sheet, c.slug),
              ),
          ],
        ),
      ),
    );
    if (slug != null) bloc.add(ActivityFormCommunityChanged(slug));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ActivityFormBloc>();
    final form = state.form!;
    final baseline = state.baseline!;
    final editing = state.editing;
    final locked = state.locked;
    final booked = state.booked;
    final currency = state.currency;
    final validation = state.validation;
    final errors = state.errors;
    final activity = state.activity;
    final community = state.community;
    final iso = zonedToIso(form.date, form.time, form.timezone);
    final priceMinor = parsePrice(form.price, currency);
    final name = baseline.title.isEmpty ? 'your activity' : baseline.title;
    final pageTitle = published ? name : (editing ? 'Edit $name' : 'Create an activity');
    final me = context.select((SessionBloc b) => b.state.profile);
    final host = activity?.host.shortName ?? (me == null ? '' : shortName(me.displayName));

    return Scaffold(
      appBar: VAppBar(leading: const ActivityFormBackButton(), title: editing ? 'Edit activity' : 'Create activity'),
      body: SafeArea(
        top: false,
        child: ScreenBody(
          controller: scroll,
          children: [
            Semantics(header: true, child: Text(pageTitle, style: VelioText.title)),
            if (published && activity != null) PublishedBanner(title: name, activity: activity),
            if (locked)
              VBanner(
                title: lockedNote,
                body:
                    '${booked == 1 ? '1 person is' : '$booked people are'} going. You can still change the title, description, photo and number of spots.',
              ),
            if (validation.isNotEmpty)
              VBanner(
                tone: BannerTone.error,
                title: summaryTitle(validation.length, editing: editing),
                body: 'They’re marked below.',
              ),
            if (state.banner != null)
              VBanner(
                tone: BannerTone.error,
                title: editing ? 'We couldn’t save your changes.' : 'We couldn’t publish this.',
                body: state.banner,
              ),
            const SectionHeading('The basics'),
            PhotoField(
              preview: state.preview,
              url: activity?.photoUrl,
              busy: state.photoBusy,
              error: errors[Field.photo],
              onPick: () => bloc.add(const ActivityFormPhotoRequested()),
            ),
            VTextField(
              label: 'Title',
              controller: title,
              placeholder: 'What are people signing up for?',
              maxLength: 200,
              error: errors[Field.title],
              onChanged: (v) => bloc.add(ActivityFormTitleChanged(v)),
            ),
            VTextField(
              label: 'Description',
              controller: description,
              placeholder: 'What happens, what to bring, who it suits',
              maxLength: 5000,
              multiline: true,
              onChanged: (v) => bloc.add(ActivityFormDescriptionChanged(v)),
            ),
            PickerField(
              label: 'Community',
              value: community?.name ?? form.communitySlug,
              onTap: editing ? null : () => _pickCommunity(context),
            ),
            const SectionHeading('When'),
            PickerField(
              label: 'Date',
              value: form.date.isEmpty ? null : formatDay(DateTime.parse('${form.date}T12:00:00Z'), 'UTC'),
              placeholder: 'Pick a date',
              error: errors[Field.date],
              onTap: locked ? null : () => _pickDate(context),
            ),
            PickerField(
              label: 'Start time',
              value: form.time.isEmpty ? null : form.time,
              placeholder: 'Pick a time',
              error: errors[Field.time],
              onTap: locked ? null : () => _pickTime(context),
            ),
            PickerField(
              label: 'Time zone',
              value: form.timezone,
              help: 'Guests see times in this zone',
              error: errors[Field.timezone],
              onTap: locked ? null : () => _pickZone(context),
            ),
            const SectionHeading('Where'),
            if (locked && activity != null) ...[
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
                value: form.location,
                center: communityCenter(form.communitySlug),
                errors: errors,
                onChanged: (v) => bloc.add(ActivityFormLocationChanged(v)),
              ),
              VTextField(
                label: 'Meeting point (optional)',
                controller: meeting,
                placeholder: 'Where exactly to find you',
                maxLength: meetingPointMax,
                help: '${form.meetingPoint.length}/$meetingPointMax',
                onChanged: (v) => bloc.add(ActivityFormMeetingPointChanged(v)),
              ),
            ],
            const SectionHeading('Price and spots'),
            VTextField(
              label: 'Price per person ($currency)',
              controller: price,
              enabled: !editing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              help: 'Guests pay you on the day. Velio takes no payment.',
              error: errors[Field.price],
              onChanged: (v) => bloc.add(ActivityFormPriceChanged(v)),
            ),
            SpotsField(
              controller: capacity,
              value: form.capacity,
              floor: state.capacityFloor,
              booked: booked,
              error: errors[Field.capacity],
              onChanged: (v) {
                capacity.text = '${v ?? ''}';
                bloc.add(ActivityFormCapacityChanged(v));
              },
              onTyped: (v) => bloc.add(ActivityFormCapacityChanged(v)),
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
              title: form.title.trim().isEmpty ? 'Your activity title' : form.title.trim(),
              meta:
                  '${iso == null ? 'Date and time' : '${formatWhen(DateTime.parse(iso), form.timezone)} ${zoneLabel(form.timezone)}'} · ${form.location?.venueName.trim().isNotEmpty ?? false ? form.location!.venueName.trim() : 'Location'}',
              photoUrl: activity?.photoUrl,
              photoBytes: state.preview,
              chip: community?.name,
              spots: ((form.capacity ?? 0) - booked).clamp(0, capacityMax),
              lines: [
                if (priceMinor != null) '${formatMoney(priceMinor, currency)} · pay the host on the day',
                if (host.isNotEmpty) 'Hosted by $host',
              ],
            ),
            VButton(
              editing ? 'Save changes' : 'Publish',
              block: true,
              loading: state.saving,
              onPressed: state.photoBusy
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      bloc.add(const ActivityFormSubmitted());
                    },
            ),
            if (!locked)
              Text(
                'Once someone books, date, time and place lock. Check them before you publish.',
                style: VelioText.caption.copyWith(color: VelioColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
