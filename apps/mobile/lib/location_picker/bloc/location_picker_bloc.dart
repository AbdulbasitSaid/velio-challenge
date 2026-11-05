// H2's location picker (S7b §4.4, FR-010; web LocationPickerLive): Places search, debounced and
// showing only the latest query's results, the details on a pick, and the pin's edits. Each edit
// becomes a new [LocationPickerState.changed] location for the form.
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/host_form.dart';
import '../../repositories/host_repository.dart';

export '../../repositories/host_repository.dart' show PlaceSuggestion;

part 'location_picker_event.dart';
part 'location_picker_state.dart';

const pinPublicNote =
    'The pin, address and meeting point are public. Anyone who sees this activity can see exactly where it is. They lock once someone books.';
const searchUnavailable = 'Place search isn’t available right now. Drop a pin on the map instead.';

/// "-1.2921" → -1.2921 when within ±[limit].
double? parseCoord(String raw, double limit) {
  final v = double.tryParse(raw.trim());
  return v != null && v.isFinite && v.abs() <= limit ? v : null;
}

const _empty = PickedLocation(placeId: null, venueName: '', addressText: '', lat: double.nan, lng: double.nan);

class LocationPickerBloc extends Bloc<LocationPickerEvent, LocationPickerState> {
  LocationPickerBloc({required HostRepository hostRepository, this.debounce = const Duration(milliseconds: 250)})
    : _host = hostRepository,
      super(LocationPickerState(placesConfigured: hostRepository.placesConfigured)) {
    on<LocationPickerQueryChanged>(_onQueryChanged, transformer: restartable());
    on<LocationPickerSuggestionPicked>(_onSuggestionPicked, transformer: restartable());
    on<LocationPickerPinDropped>(_onPinDropped);
    on<LocationPickerVenueChanged>((e, emit) => _change(emit, (e.value ?? _empty).copyWith(venueName: e.venueName)));
    on<LocationPickerAddressChanged>(
      (e, emit) => _change(emit, (e.value ?? _empty).copyWith(addressText: e.addressText)),
    );
    on<LocationPickerCoordinatesChanged>(_onCoordinatesChanged);
    on<LocationPickerMapMoved>(_onMapMoved);
  }

  final HostRepository _host;
  final Duration debounce;

  void _change(Emitter<LocationPickerState> emit, PickedLocation? location, {bool fill = false}) =>
      emit(state.copyWith(changed: () => location, changes: state.changes + 1, fills: fill ? state.fills + 1 : null));

  Future<void> _onQueryChanged(LocationPickerQueryChanged event, Emitter<LocationPickerState> emit) async {
    final q = event.query.trim();
    emit(state.copyWith(query: q));
    if (q.length < 2) {
      emit(state.copyWith(results: () => null));
      return;
    }
    // A newer query cancels this one (restartable), so only the latest results land.
    await Future<void>.delayed(debounce);
    if (emit.isDone) return;
    final at = event.value != null && event.value!.lat.isFinite ? event.value! : null;
    try {
      final results = await _host.searchPlaces(q, lat: at?.lat ?? event.center.lat, lng: at?.lng ?? event.center.lng);
      if (emit.isDone) return;
      emit(state.copyWith(searchFailed: false, results: () => results));
    } catch (_) {
      if (!emit.isDone) emit(state.copyWith(searchFailed: true));
    }
  }

  Future<void> _onSuggestionPicked(LocationPickerSuggestionPicked event, Emitter<LocationPickerState> emit) async {
    emit(state.copyWith(results: () => null));
    try {
      final picked = await _host.placeDetails(event.suggestion);
      emit(state.copyWith(query: picked.venueName, picks: state.picks + 1));
      _change(emit, picked, fill: true);
    } catch (_) {
      emit(state.copyWith(searchFailed: true));
    }
  }

  /// "Drop a pin without a place": at the community's centre unless there is one already.
  void _onPinDropped(LocationPickerPinDropped event, Emitter<LocationPickerState> emit) => _change(
    emit,
    event.value ??
        PickedLocation(placeId: null, venueName: '', addressText: '', lat: event.center.lat, lng: event.center.lng),
    fill: true,
  );

  void _onCoordinatesChanged(LocationPickerCoordinatesChanged event, Emitter<LocationPickerState> emit) {
    final lat = parseCoord(event.lat, 90), lng = parseCoord(event.lng, 180);
    emit(
      state.copyWith(
        latError: () => event.lat.isNotEmpty && lat == null ? 'Between -90 and 90' : null,
        lngError: () => event.lng.isNotEmpty && lng == null ? 'Between -180 and 180' : null,
      ),
    );
    _change(emit, (event.value ?? _empty).copyWith(lat: lat ?? double.nan, lng: lng ?? double.nan));
  }

  /// The pin is the map's centre: where the map stops is the new pin.
  void _onMapMoved(LocationPickerMapMoved event, Emitter<LocationPickerState> emit) {
    final current = event.value ?? _empty;
    if ((event.lat - current.lat).abs() < 1e-7 && (event.lng - current.lng).abs() < 1e-7) return;
    _change(emit, current.copyWith(lat: event.lat, lng: event.lng));
  }
}
