part of 'activity_form_bloc.dart';

sealed class ActivityFormEvent extends Equatable {
  const ActivityFormEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, or Try again.
final class ActivityFormRequested extends ActivityFormEvent {
  const ActivityFormRequested();
}

final class ActivityFormTitleChanged extends ActivityFormEvent {
  const ActivityFormTitleChanged(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

final class ActivityFormDescriptionChanged extends ActivityFormEvent {
  const ActivityFormDescriptionChanged(this.description);
  final String description;

  @override
  List<Object?> get props => [description];
}

final class ActivityFormCommunityChanged extends ActivityFormEvent {
  const ActivityFormCommunityChanged(this.slug);
  final String slug;

  @override
  List<Object?> get props => [slug];
}

/// The date picked, as a calendar day.
final class ActivityFormDateChanged extends ActivityFormEvent {
  const ActivityFormDateChanged(this.date);
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class ActivityFormTimeChanged extends ActivityFormEvent {
  const ActivityFormTimeChanged(this.hour, this.minute);
  final int hour;
  final int minute;

  @override
  List<Object?> get props => [hour, minute];
}

final class ActivityFormTimezoneChanged extends ActivityFormEvent {
  const ActivityFormTimezoneChanged(this.timezone);
  final String timezone;

  @override
  List<Object?> get props => [timezone];
}

final class ActivityFormLocationChanged extends ActivityFormEvent {
  const ActivityFormLocationChanged(this.location);
  final PickedLocation? location;

  @override
  List<Object?> get props => [location];
}

final class ActivityFormMeetingPointChanged extends ActivityFormEvent {
  const ActivityFormMeetingPointChanged(this.meetingPoint);
  final String meetingPoint;

  @override
  List<Object?> get props => [meetingPoint];
}

final class ActivityFormPriceChanged extends ActivityFormEvent {
  const ActivityFormPriceChanged(this.price);
  final String price;

  @override
  List<Object?> get props => [price];
}

/// Null while the field is empty.
final class ActivityFormCapacityChanged extends ActivityFormEvent {
  const ActivityFormCapacityChanged(this.capacity);
  final int? capacity;

  @override
  List<Object?> get props => [capacity];
}

/// Choose a photo, or Change photo.
final class ActivityFormPhotoRequested extends ActivityFormEvent {
  const ActivityFormPhotoRequested();
}

/// Publish, or Save changes.
final class ActivityFormSubmitted extends ActivityFormEvent {
  const ActivityFormSubmitted();
}
