// LocationPickerBloc (V-BLOC-1): debounced search where only the latest query's results land, the
// failure fallback, picks, a dropped pin, typed coordinates and map moves.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:velio/domain/host_form.dart';
import 'package:velio/location_picker/location_picker.dart';
import 'package:velio/repositories/host_repository.dart';

class MockHostRepository extends Mock implements HostRepository {}

const _center = (lat: -1.2921, lng: 36.8219);
const _boat = PlaceSuggestion(id: 'p1', name: 'Boat Club', sub: 'Naivasha');
const _picked = PickedLocation(placeId: 'p1', venueName: 'Boat Club', addressText: 'Moi Rd', lat: -0.77, lng: 36.43);

void main() {
  late MockHostRepository host;

  setUp(() {
    host = MockHostRepository();
    when(() => host.placesConfigured).thenReturn(true);
  });

  LocationPickerBloc build() => LocationPickerBloc(hostRepository: host, debounce: const Duration(milliseconds: 20));

  test('only the latest query searches, near the community', () async {
    when(
      () => host.searchPlaces(
        any(),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer((_) async => [_boat]);
    final b = build()
      ..add(const LocationPickerQueryChanged('bo', value: null, center: _center))
      ..add(const LocationPickerQueryChanged('boat', value: null, center: _center));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    verify(() => host.searchPlaces('boat', lat: _center.lat, lng: _center.lng)).called(1);
    verifyNever(
      () => host.searchPlaces(
        'bo',
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    );
    expect(b.state.showResults, isTrue);
    await b.close();
  });

  blocTest<LocationPickerBloc, LocationPickerState>(
    'one character clears the list without searching',
    build: build,
    act: (b) => b.add(const LocationPickerQueryChanged('b', value: null, center: _center)),
    expect: () => [const LocationPickerState(placesConfigured: true, query: 'b')],
  );

  test('a failed search falls back to the pin', () async {
    when(
      () => host.searchPlaces(
        any(),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer((_) async => throw Exception('down'));
    final b = build()..add(const LocationPickerQueryChanged('boat', value: null, center: _center));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(b.state.message(maps: true), searchUnavailable);
    expect(b.state.message(maps: false), isNull);
    await b.close();
  });

  blocTest<LocationPickerBloc, LocationPickerState>(
    'a pick fills the fields and changes the location',
    setUp: () => when(() => host.placeDetails(_boat)).thenAnswer((_) async => _picked),
    build: build,
    act: (b) => b.add(const LocationPickerSuggestionPicked(_boat)),
    verify: (b) {
      expect((b.state.changed, b.state.changes, b.state.fills, b.state.picks), (_picked, 1, 1, 1));
      expect(b.state.query, 'Boat Club');
    },
  );

  blocTest<LocationPickerBloc, LocationPickerState>(
    'a failed pick says search is unavailable',
    setUp: () => when(() => host.placeDetails(_boat)).thenAnswer((_) async => throw Exception('down')),
    build: build,
    act: (b) => b.add(const LocationPickerSuggestionPicked(_boat)),
    verify: (b) => expect((b.state.searchFailed, b.state.changes), (true, 0)),
  );

  blocTest<LocationPickerBloc, LocationPickerState>(
    'a dropped pin starts at the community’s centre',
    build: build,
    act: (b) => b.add(const LocationPickerPinDropped(value: null, center: _center)),
    verify: (b) => expect((b.state.changed!.lat, b.state.changed!.lng, b.state.fills), (_center.lat, _center.lng, 1)),
  );

  blocTest<LocationPickerBloc, LocationPickerState>(
    'typed coordinates are checked',
    build: build,
    act: (b) => b.add(const LocationPickerCoordinatesChanged(lat: '95', lng: '36.8', value: null)),
    verify: (b) {
      expect((b.state.latError, b.state.lngError), ('Between -90 and 90', null));
      expect(b.state.changed!.lat.isNaN, isTrue);
      expect(b.state.changed!.lng, 36.8);
    },
  );

  blocTest<LocationPickerBloc, LocationPickerState>(
    'the map moves the pin, but not for a tiny drift; venue and address edits keep the place',
    build: build,
    act: (b) => b
      ..add(const LocationPickerMapMoved(-0.77, 36.43, value: _picked))
      ..add(const LocationPickerMapMoved(-0.78, 36.43, value: _picked))
      ..add(const LocationPickerVenueChanged('Club', value: _picked))
      ..add(const LocationPickerAddressChanged('Lake Rd', value: _picked)),
    verify: (b) {
      expect(b.state.changes, 3);
      expect((b.state.changed!.addressText, b.state.changed!.placeId), ('Lake Rd', 'p1'));
    },
  );
}
