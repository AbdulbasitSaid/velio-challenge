part of 'activity_form_bloc.dart';

final class ActivityFormState extends Equatable {
  const ActivityFormState({
    this.id,
    this.communities,
    this.activity,
    this.error,
    this.form,
    this.baseline,
    this.loaded = 0,
    this.preview,
    this.photoBusy = false,
    this.photoFailed,
    this.showErrors = false,
    this.validation = const {},
    this.apiErrors = const {},
    this.banner,
    this.saving = false,
    this.publishedId,
    this.saves = 0,
    this.scrolls = 0,
  });

  /// Null when creating.
  final String? id;

  /// Null until loaded.
  final List<Community>? communities;
  final PublicActivity? activity;
  final LoadError? error;
  final HostForm? form;

  /// The values last saved, for the changed-only PATCH.
  final HostForm? baseline;

  /// Counts loads, so the text fields take the loaded values.
  final int loaded;

  /// The uploaded photo, shown until the page reloads.
  final Uint8List? preview;
  final bool photoBusy;
  final String? photoFailed;
  final bool showErrors;

  /// The copy deck's errors, once Publish or Save has been tried.
  final FormErrors validation;
  final FormErrors apiErrors;
  final String? banner;
  final bool saving;

  /// Set once Publish created the activity: the page goes to its edit view.
  final String? publishedId;

  /// Counts saves, for "Changes saved".
  final int saves;

  /// Counts the times the form should scroll to its summary.
  final int scrolls;

  bool get editing => id != null;
  bool get ready => communities != null;
  int get booked => activity?.members.count ?? 0;
  bool get locked => booked > 0;
  String get currency => activity?.currency ?? communityCurrency(form!.communitySlug);

  /// The spots stepper never goes below the people booked.
  int get capacityFloor => booked > 1 ? booked : 1;

  /// Every error a field shows.
  FormErrors get errors => {...validation, ...apiErrors, Field.photo: ?photoFailed};

  Community? get community => communities?.where((c) => c.slug == form?.communitySlug).firstOrNull;

  ActivityFormState copyWith({
    List<Community>? Function()? communities,
    PublicActivity? Function()? activity,
    LoadError? Function()? error,
    HostForm? form,
    HostForm? baseline,
    int? loaded,
    Uint8List? Function()? preview,
    bool? photoBusy,
    String? Function()? photoFailed,
    bool? showErrors,
    FormErrors? validation,
    FormErrors? apiErrors,
    String? Function()? banner,
    bool? saving,
    String? Function()? publishedId,
    int? saves,
    int? scrolls,
  }) => ActivityFormState(
    id: id,
    communities: communities != null ? communities() : this.communities,
    activity: activity != null ? activity() : this.activity,
    error: error != null ? error() : this.error,
    form: form ?? this.form,
    baseline: baseline ?? this.baseline,
    loaded: loaded ?? this.loaded,
    preview: preview != null ? preview() : this.preview,
    photoBusy: photoBusy ?? this.photoBusy,
    photoFailed: photoFailed != null ? photoFailed() : this.photoFailed,
    showErrors: showErrors ?? this.showErrors,
    validation: validation ?? this.validation,
    apiErrors: apiErrors ?? this.apiErrors,
    banner: banner != null ? banner() : this.banner,
    saving: saving ?? this.saving,
    publishedId: publishedId != null ? publishedId() : this.publishedId,
    saves: saves ?? this.saves,
    scrolls: scrolls ?? this.scrolls,
  );

  @override
  List<Object?> get props => [
    id,
    communities,
    activity,
    error,
    form,
    baseline,
    loaded,
    preview,
    photoBusy,
    photoFailed,
    showErrors,
    validation,
    apiErrors,
    banner,
    saving,
    publishedId,
    saves,
    scrolls,
  ];
}
