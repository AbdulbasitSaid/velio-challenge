// H2's location picker (S7b §4.4, FR-010; web LocationPickerLive): Places search prefills venue,
// address and the pin; with native maps the pin sits at the map's centre and the map drags under it;
// "Drop a pin without a place" starts at the community's centre. Without Maps the pin is typed in as
// coordinates (web ManualLocation, Maps FR-021). Without a Places key, search says it's unavailable.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../app/config.dart';
import '../../domain/host_form.dart';
import '../../repositories/host_repository.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';
import '../bloc/location_picker_bloc.dart';
import '../widgets/pin_map.dart';
import '../widgets/place_results.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.center,
    this.errors = const {},
  });
  final PickedLocation? value;
  final ValueChanged<PickedLocation?> onChanged;

  /// Where "Drop a pin" starts and what search prefers: the community's city.
  final ({double lat, double lng}) center;
  final FormErrors errors;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => LocationPickerBloc(hostRepository: context.read<HostRepository>()),
    child: LocationPickerView(value: value, onChanged: onChanged, center: center, errors: errors),
  );
}

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({
    super.key,
    required this.value,
    required this.onChanged,
    required this.center,
    this.errors = const {},
  });
  final PickedLocation? value;
  final ValueChanged<PickedLocation?> onChanged;
  final ({double lat, double lng}) center;
  final FormErrors errors;

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final _search = TextEditingController();
  late final _venue = TextEditingController(text: widget.value?.venueName ?? '');
  late final _address = TextEditingController(text: widget.value?.addressText ?? '');
  late final _lat = TextEditingController(text: _coordText(widget.value?.lat));
  late final _lng = TextEditingController(text: _coordText(widget.value?.lng));
  GoogleMapController? _map;

  static String _coordText(double? v) => v == null || !v.isFinite ? '' : '$v';

  @override
  void dispose() {
    for (final c in [_search, _venue, _address, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(PickedLocation p) {
    _venue.text = p.venueName;
    _address.text = p.addressText;
    _lat.text = _coordText(p.lat);
    _lng.text = _coordText(p.lng);
  }

  void _coordinates() => context.read<LocationPickerBloc>().add(
    LocationPickerCoordinatesChanged(lat: _lat.text, lng: _lng.text, value: widget.value),
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationPickerBloc>();
    final state = context.watch<LocationPickerBloc>().state;
    final places = state.placesConfigured;
    final maps = context.read<AppConfig>().mapsEnabled;
    final value = widget.value;
    final message = state.message(maps: maps);
    final hasPin = value != null && value.lat.isFinite && value.lng.isFinite;
    final errors = widget.errors;

    return MultiBlocListener(
      listeners: [
        BlocListener<LocationPickerBloc, LocationPickerState>(
          listenWhen: (a, b) => a.changes != b.changes,
          listener: (context, state) => widget.onChanged(state.changed),
        ),
        BlocListener<LocationPickerBloc, LocationPickerState>(
          listenWhen: (a, b) => a.fills != b.fills,
          listener: (context, state) => _fill(state.changed!),
        ),
        BlocListener<LocationPickerBloc, LocationPickerState>(
          listenWhen: (a, b) => a.picks != b.picks,
          listener: (context, state) {
            final p = state.changed!;
            _search.text = p.venueName;
            _map?.moveCamera(CameraUpdate.newLatLng(LatLng(p.lat, p.lng)));
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (places) ...[
            VTextField(
              label: 'Location',
              controller: _search,
              placeholder: 'Search for a place or address',
              error: message ?? (value == null ? errors[Field.location] : null),
              textInputAction: TextInputAction.search,
              onChanged: (q) => bloc.add(LocationPickerQueryChanged(q, value: value, center: widget.center)),
            ),
            if (state.showResults) ...[
              const SizedBox(height: VelioSpace.s2),
              PlaceResults(results: state.results!, onPicked: (s) => bloc.add(LocationPickerSuggestionPicked(s))),
            ],
          ] else if (message != null) ...[
            Text(message, style: VelioText.caption.copyWith(color: VelioColors.danger)),
          ],
          if (maps) ...[
            const SizedBox(height: VelioSpace.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: VButton(
                'Drop a pin without a place',
                icon: 'target',
                variant: ButtonVariant.quiet,
                small: true,
                onPressed: () => bloc.add(LocationPickerPinDropped(value: value, center: widget.center)),
              ),
            ),
            if (!places && value == null && errors[Field.location] != null)
              Text(errors[Field.location]!, style: VelioText.caption.copyWith(color: VelioColors.danger)),
          ],
          if (maps && hasPin) ...[
            const SizedBox(height: VelioSpace.s3),
            PinMap(
              lat: value.lat,
              lng: value.lng,
              onCreated: (c) => _map = c,
              onStopped: (t) => bloc.add(LocationPickerMapMoved(t.latitude, t.longitude, value: widget.value)),
            ),
          ],
          if (!maps || value != null) ...[
            const SizedBox(height: VelioSpace.s3),
            VTextField(
              label: 'Venue name',
              controller: _venue,
              maxLength: 200,
              error: errors[Field.venueName],
              onChanged: (v) => bloc.add(LocationPickerVenueChanged(v, value: value)),
            ),
            const SizedBox(height: VelioSpace.s3),
            VTextField(
              label: 'Address',
              controller: _address,
              maxLength: 500,
              error: errors[Field.addressText],
              onChanged: (v) => bloc.add(LocationPickerAddressChanged(v, value: value)),
            ),
          ],
          if (!maps) ...[
            const SizedBox(height: VelioSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: VTextField(
                    label: 'Latitude',
                    controller: _lat,
                    placeholder: '-1.2921',
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    error: state.latError,
                    onChanged: (_) => _coordinates(),
                  ),
                ),
                const SizedBox(width: VelioSpace.s3),
                Expanded(
                  child: VTextField(
                    label: 'Longitude',
                    controller: _lng,
                    placeholder: '36.8219',
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    error: state.lngError,
                    onChanged: (_) => _coordinates(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              errors[Field.location] ?? 'Copy the pin’s coordinates from any map app.',
              style: VelioText.caption.copyWith(
                color: errors[Field.location] != null ? VelioColors.danger : VelioColors.muted,
              ),
            ),
          ],
          const SizedBox(height: VelioSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VIcon('info', size: 18),
              const SizedBox(width: VelioSpace.s2),
              Expanded(
                child: Text(pinPublicNote, style: VelioText.caption.copyWith(color: VelioColors.muted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
