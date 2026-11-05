part of 'location_picker_bloc.dart';

final class LocationPickerState extends Equatable {
  const LocationPickerState({
    required this.placesConfigured,
    this.query = '',
    this.results,
    this.searchFailed = false,
    this.latError,
    this.lngError,
    this.changed,
    this.changes = 0,
    this.fills = 0,
    this.picks = 0,
  });

  /// False without `PLACES_KEY`: search says it's unavailable.
  final bool placesConfigured;
  final String query;

  /// Null when there's nothing to list.
  final List<PlaceSuggestion>? results;
  final bool searchFailed;
  final String? latError;
  final String? lngError;

  /// The latest location for the form; [changes] counts them.
  final PickedLocation? changed;
  final int changes;

  /// Counts the times the fields should take [changed]'s values (a pick or a dropped pin).
  final int fills;

  /// Counts picks: the search field shows the venue and the map moves to it.
  final int picks;

  bool get showResults => results != null && results!.isNotEmpty && query.length >= 2;

  /// The line under search (or in its place): unavailable, or no matches.
  String? message({required bool maps}) {
    final noResults = results != null && results!.isEmpty && query.length >= 2;
    if (!placesConfigured || searchFailed) return maps ? searchUnavailable : null;
    if (noResults) return 'No places match “$query”. Check the spelling, or drop a pin on the map.';
    return null;
  }

  LocationPickerState copyWith({
    String? query,
    List<PlaceSuggestion>? Function()? results,
    bool? searchFailed,
    String? Function()? latError,
    String? Function()? lngError,
    PickedLocation? Function()? changed,
    int? changes,
    int? fills,
    int? picks,
  }) => LocationPickerState(
    placesConfigured: placesConfigured,
    query: query ?? this.query,
    results: results != null ? results() : this.results,
    searchFailed: searchFailed ?? this.searchFailed,
    latError: latError != null ? latError() : this.latError,
    lngError: lngError != null ? lngError() : this.lngError,
    changed: changed != null ? changed() : this.changed,
    changes: changes ?? this.changes,
    fills: fills ?? this.fills,
    picks: picks ?? this.picks,
  );

  @override
  List<Object?> get props => [
    placesConfigured,
    query,
    results,
    searchFailed,
    latError,
    lngError,
    changed,
    changes,
    fills,
    picks,
  ];
}
