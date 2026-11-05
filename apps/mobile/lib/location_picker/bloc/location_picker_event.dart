part of 'location_picker_bloc.dart';

/// Each event carries the form's current [value] and the community's [center] where it needs them.
sealed class LocationPickerEvent extends Equatable {
  const LocationPickerEvent();

  @override
  List<Object?> get props => [];
}

final class LocationPickerQueryChanged extends LocationPickerEvent {
  const LocationPickerQueryChanged(this.query, {required this.value, required this.center});
  final String query;
  final PickedLocation? value;
  final ({double lat, double lng}) center;

  @override
  List<Object?> get props => [query, value, center];
}

final class LocationPickerSuggestionPicked extends LocationPickerEvent {
  const LocationPickerSuggestionPicked(this.suggestion);
  final PlaceSuggestion suggestion;

  @override
  List<Object?> get props => [suggestion.id];
}

final class LocationPickerPinDropped extends LocationPickerEvent {
  const LocationPickerPinDropped({required this.value, required this.center});
  final PickedLocation? value;
  final ({double lat, double lng}) center;

  @override
  List<Object?> get props => [value, center];
}

final class LocationPickerVenueChanged extends LocationPickerEvent {
  const LocationPickerVenueChanged(this.venueName, {required this.value});
  final String venueName;
  final PickedLocation? value;

  @override
  List<Object?> get props => [venueName, value];
}

final class LocationPickerAddressChanged extends LocationPickerEvent {
  const LocationPickerAddressChanged(this.addressText, {required this.value});
  final String addressText;
  final PickedLocation? value;

  @override
  List<Object?> get props => [addressText, value];
}

/// Latitude and longitude as typed (no native maps).
final class LocationPickerCoordinatesChanged extends LocationPickerEvent {
  const LocationPickerCoordinatesChanged({required this.lat, required this.lng, required this.value});
  final String lat;
  final String lng;
  final PickedLocation? value;

  @override
  List<Object?> get props => [lat, lng, value];
}

/// The map stopped with its centre here.
final class LocationPickerMapMoved extends LocationPickerEvent {
  const LocationPickerMapMoved(this.lat, this.lng, {required this.value});
  final double lat;
  final double lng;
  final PickedLocation? value;

  @override
  List<Object?> get props => [lat, lng, value];
}
