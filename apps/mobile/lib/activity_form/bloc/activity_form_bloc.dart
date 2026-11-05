// H2 create and edit (S7b FR-007–FR-010; web activity-form.tsx): the form, its copy-deck validation,
// the photo pipeline, and Publish or a changed-only Save. After the first booking, date, time, zone
// and place are locked; the API's `location_locked` and `capacity_below_bookings` land on their
// fields and the snapshot is fetched again.
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:velio_api/velio_api.dart';

import '../../domain/api_exception.dart';
import '../../domain/host_form.dart';
import '../../domain/load_error.dart';
import '../../repositories/host_repository.dart';

part 'activity_form_event.dart';
part 'activity_form_state.dart';

const photoUnreadable = 'We couldn’t read that photo. Try a JPG or PNG.';
const photoUploadFailed = 'We couldn’t upload the photo. Check your connection and try again.';

class ActivityFormBloc extends Bloc<ActivityFormEvent, ActivityFormState> {
  ActivityFormBloc({required HostRepository hostRepository, String? id, this._clock = DateTime.now})
    : _host = hostRepository,
      super(ActivityFormState(id: id)) {
    on<ActivityFormRequested>(_onRequested);
    on<ActivityFormTitleChanged>((e, emit) => _set(emit, state.form!.copyWith(title: e.title), {Field.title}));
    on<ActivityFormDescriptionChanged>((e, emit) => _set(emit, state.form!.copyWith(description: e.description), {}));
    on<ActivityFormCommunityChanged>(_onCommunityChanged);
    on<ActivityFormDateChanged>((e, emit) => _set(emit, state.form!.copyWith(date: _date(e.date)), {Field.date}));
    on<ActivityFormTimeChanged>(
      (e, emit) => _set(emit, state.form!.copyWith(time: '${_two(e.hour)}:${_two(e.minute)}'), {Field.time}),
    );
    on<ActivityFormTimezoneChanged>(
      (e, emit) => _set(emit, state.form!.copyWith(timezone: e.timezone), {Field.timezone}),
    );
    on<ActivityFormLocationChanged>(
      (e, emit) => _set(emit, state.form!.copyWith(location: () => e.location), {
        Field.location,
        Field.venueName,
        Field.addressText,
      }),
    );
    on<ActivityFormMeetingPointChanged>(
      (e, emit) => _set(emit, state.form!.copyWith(meetingPoint: e.meetingPoint), {}),
    );
    on<ActivityFormPriceChanged>((e, emit) => _set(emit, state.form!.copyWith(price: e.price), {Field.price}));
    on<ActivityFormCapacityChanged>(
      (e, emit) => _set(emit, state.form!.copyWith(capacity: () => e.capacity), {Field.capacity}),
    );
    on<ActivityFormPhotoRequested>(_onPhotoRequested, transformer: droppable());
    on<ActivityFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final HostRepository _host;
  final DateTime Function() _clock;

  Future<void> _onRequested(ActivityFormRequested event, Emitter<ActivityFormState> emit) async {
    emit(state.copyWith(error: () => null));
    try {
      final communities = (await _host.communities()).communities;
      PublicActivity? activity;
      if (state.id != null) {
        activity = await _host.activity(state.id!);
        // Anyone but the host gets X4's not-found (S5 SEC-008).
        if (!(activity.viewer?.isHost ?? false)) throw const ApiException(status: 404, code: 'not_found');
      }
      final slug = communities.isEmpty ? 'explore-kenya' : communities.first.slug;
      final form = activity != null
          ? formFromActivity(activity)
          : HostForm(communitySlug: slug, timezone: communityZone(slug));
      emit(
        state.copyWith(
          communities: () => communities,
          activity: () => activity,
          form: form,
          baseline: form,
          loaded: state.loaded + 1,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(error: () => LoadError.of(e, notFound: const {400, 403, 404})));
    }
  }

  /// A new form value; edits clear the API's errors on the fields they touch.
  void _set(Emitter<ActivityFormState> emit, HostForm next, Set<Field> touched) {
    var apiErrors = state.apiErrors;
    if (apiErrors.isNotEmpty) {
      apiErrors = {...apiErrors};
      for (final f in touched) {
        apiErrors.remove(f);
      }
      if (touched.contains(Field.location) || touched.contains(Field.date)) {
        apiErrors
          ..remove(Field.location)
          ..remove(Field.date);
      }
    }
    emit(_validated(state.copyWith(form: next, apiErrors: apiErrors)));
  }

  /// Validation shows once Publish or Save has been tried, and follows every edit after that.
  ActivityFormState _validated(ActivityFormState s) =>
      s.copyWith(validation: s.showErrors ? _validate(s) : const <Field, String>{});

  FormErrors _validate(ActivityFormState s) =>
      validate(s.form!, editing: s.editing, locked: s.locked, booked: s.booked, currency: s.currency, now: _clock());

  void _onCommunityChanged(ActivityFormCommunityChanged event, Emitter<ActivityFormState> emit) {
    final form = state.form!;
    if (event.slug == form.communitySlug) return;
    // A new activity follows its community's zone until the host picks one (S7b PLANNING §12 D3).
    final followZone = form.timezone == communityZone(form.communitySlug);
    _set(
      emit,
      form.copyWith(communitySlug: event.slug, timezone: followZone ? communityZone(event.slug) : null),
      const {},
    );
  }

  Future<void> _onPhotoRequested(ActivityFormPhotoRequested event, Emitter<ActivityFormState> emit) async {
    final Uint8List? picked;
    try {
      picked = await _host.pickPhoto();
    } catch (_) {
      emit(state.copyWith(photoFailed: () => photoUnreadable));
      return;
    }
    if (picked == null) return;
    emit(state.copyWith(photoBusy: true, photoFailed: () => null));
    try {
      final up = await _host.uploadPhoto(picked);
      emit(state.copyWith(preview: () => up.preview));
      _set(emit, state.form!.copyWith(photoKey: () => up.key), {Field.photo});
    } on PhotoError catch (e) {
      emit(state.copyWith(photoFailed: () => e.unreadable ? photoUnreadable : photoUploadFailed));
    } finally {
      emit(state.copyWith(photoBusy: false));
    }
  }

  Future<void> _onSubmitted(ActivityFormSubmitted event, Emitter<ActivityFormState> emit) async {
    emit(state.copyWith(banner: () => null));
    if (_validate(state).isNotEmpty) {
      emit(_validated(state.copyWith(showErrors: true, scrolls: state.scrolls + 1)));
      return;
    }
    emit(state.copyWith(saving: true));
    try {
      if (!state.editing) {
        final id = await _host.create(createBody(state.form!));
        // Saving stays on while the page is replaced by the published one.
        emit(state.copyWith(publishedId: () => id));
        return;
      }
      final patch = patchBody(state.form!, state.baseline!, locked: state.locked);
      if (patch.isNotEmpty) await _host.patch(state.id!, patch);
      emit(_validated(state.copyWith(baseline: state.form, showErrors: false, saving: false, saves: state.saves + 1)));
    } catch (err) {
      emit(state.copyWith(saving: false));
      switch (saveFailure(err)) {
        case BannerFailure(:final text):
          emit(state.copyWith(banner: () => text, scrolls: state.scrolls + 1));
        case FieldFailure(:final fields, :final refresh):
          emit(state.copyWith(apiErrors: fields, scrolls: state.scrolls + 1));
          // The booking count changed: fetch the snapshot again.
          if (refresh) {
            try {
              final a = await _host.activity(state.id!);
              emit(_validated(state.copyWith(activity: () => a)));
            } catch (_) {}
          }
      }
    }
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
