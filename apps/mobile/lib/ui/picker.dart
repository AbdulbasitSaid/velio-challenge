// H2's location picker (S7b §4.4, FR-010; web LocationPickerLive): Places search prefills venue,
// address and the pin; with native maps the pin sits at the map's centre and the map drags under it;
// "Drop a pin without a place" starts at the community's centre. Without Maps the pin is typed in as
// coordinates (web ManualLocation, Maps FR-021). Without a Places key, search says it's unavailable.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/host_form.dart';
import '../core/places.dart';
import '../core/providers.dart';
import 'art.dart';
import 'components.dart';

const pinPublicNote =
    'The pin, address and meeting point are public. Anyone who sees this activity can see exactly where it is. They lock once someone books.';
const searchUnavailable = 'Place search isn’t available right now. Drop a pin on the map instead.';

/// "-1.2921" → -1.2921 when within ±[limit].
double? parseCoord(String raw, double limit) {
  final v = double.tryParse(raw.trim());
  return v != null && v.isFinite && v.abs() <= limit ? v : null;
}

class LocationPicker extends ConsumerStatefulWidget {
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
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  final _search = TextEditingController();
  late final _venue = TextEditingController(text: widget.value?.venueName ?? '');
  late final _address = TextEditingController(text: widget.value?.addressText ?? '');
  late final _lat = TextEditingController(text: _coordText(widget.value?.lat));
  late final _lng = TextEditingController(text: _coordText(widget.value?.lng));
  Timer? _debounce;
  int _request = 0;
  List<PlaceSuggestion>? _results;
  bool _searchFailed = false;
  GoogleMapController? _map;

  /// Where the map is moving to; applied as the pin when it stops.
  LatLng? _pending;

  static String _coordText(double? v) => v == null || !v.isFinite ? '' : '$v';

  PickedLocation get _current =>
      widget.value ??
      const PickedLocation(placeId: null, venueName: '', addressText: '', lat: double.nan, lng: double.nan);

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_search, _venue, _address, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    final n = ++_request;
    if (q.trim().length < 2) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final at = widget.value != null && widget.value!.lat.isFinite ? widget.value! : null;
      try {
        final results = await ref
            .read(placesProvider)
            .search(q.trim(), lat: at?.lat ?? widget.center.lat, lng: at?.lng ?? widget.center.lng);
        if (!mounted || n != _request) return;
        setState(() {
          _searchFailed = false;
          _results = results;
        });
      } catch (_) {
        if (mounted && n == _request) setState(() => _searchFailed = true);
      }
    });
  }

  Future<void> _pick(PlaceSuggestion s) async {
    setState(() => _results = null);
    try {
      final picked = await ref.read(placesProvider).details(s);
      if (!mounted) return;
      _search.text = picked.venueName;
      _fill(picked);
      widget.onChanged(picked);
      _map?.moveCamera(CameraUpdate.newLatLng(LatLng(picked.lat, picked.lng)));
    } catch (_) {
      if (mounted) setState(() => _searchFailed = true);
    }
  }

  void _fill(PickedLocation p) {
    _venue.text = p.venueName;
    _address.text = p.addressText;
    _lat.text = _coordText(p.lat);
    _lng.text = _coordText(p.lng);
  }

  void _dropPin() {
    final p =
        widget.value ??
        PickedLocation(placeId: null, venueName: '', addressText: '', lat: widget.center.lat, lng: widget.center.lng);
    _fill(p);
    widget.onChanged(p);
  }

  void _setCoord() => widget.onChanged(
    _current.copyWith(lat: parseCoord(_lat.text, 90) ?? double.nan, lng: parseCoord(_lng.text, 180) ?? double.nan),
  );

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesProvider).configured;
    final maps = ref.watch(mapsEnabledProvider);
    final value = widget.value;
    final q = _search.text.trim();
    final results = _results;
    final noResults = results != null && results.isEmpty && q.length >= 2;
    final message = !places || _searchFailed
        ? (maps ? searchUnavailable : null)
        : noResults
        ? 'No places match “$q”. Check the spelling, or drop a pin on the map.'
        : null;
    final hasPin = value != null && value.lat.isFinite && value.lng.isFinite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (places) ...[
          VTextField(
            label: 'Location',
            controller: _search,
            placeholder: 'Search for a place or address',
            error: message ?? (value == null ? widget.errors[Field.location] : null),
            textInputAction: TextInputAction.search,
            onChanged: _onQuery,
          ),
          if (results != null && results.isNotEmpty && q.length >= 2) ...[
            const SizedBox(height: VelioSpace.s2),
            VList([
              for (final r in results)
                InkWell(
                  onTap: () => _pick(r),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: VelioSize.touchMin),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 10),
                      child: Row(
                        children: [
                          const VIcon('pin'),
                          const SizedBox(width: VelioSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: VelioText.bodyStrong),
                                if (r.sub.isNotEmpty)
                                  Text(r.sub, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(VelioSpace.s2),
                child: Text(
                  'Search by Google',
                  textAlign: TextAlign.right,
                  style: VelioText.caption.copyWith(color: VelioColors.muted),
                ),
              ),
            ]),
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
              onPressed: _dropPin,
            ),
          ),
          if (!places && value == null && widget.errors[Field.location] != null)
            Text(widget.errors[Field.location]!, style: VelioText.caption.copyWith(color: VelioColors.danger)),
        ],
        if (maps && hasPin) ...[
          const SizedBox(height: VelioSpace.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(VelioRadius.card),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Semantics(
                    label: 'Map. Drag it to move the pin.',
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(value.lat, value.lng), zoom: 16),
                      onMapCreated: (c) => _map = c,
                      // The pin is the map's centre: dragging the map moves it.
                      onCameraMove: (p) => _pending = p.target,
                      onCameraIdle: () {
                        final t = _pending;
                        if (t == null) return;
                        _pending = null;
                        if ((t.latitude - _current.lat).abs() < 1e-7 && (t.longitude - _current.lng).abs() < 1e-7) {
                          return;
                        }
                        widget.onChanged(_current.copyWith(lat: t.latitude, lng: t.longitude));
                      },
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                  const IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 34),
                      child: VIcon('pin', size: 40, color: VelioColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!maps || value != null) ...[
          const SizedBox(height: VelioSpace.s3),
          VTextField(
            label: 'Venue name',
            controller: _venue,
            maxLength: 200,
            error: widget.errors[Field.venueName],
            onChanged: (v) => widget.onChanged(_current.copyWith(venueName: v)),
          ),
          const SizedBox(height: VelioSpace.s3),
          VTextField(
            label: 'Address',
            controller: _address,
            maxLength: 500,
            error: widget.errors[Field.addressText],
            onChanged: (v) => widget.onChanged(_current.copyWith(addressText: v)),
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
                  error: _lat.text.isNotEmpty && parseCoord(_lat.text, 90) == null ? 'Between -90 and 90' : null,
                  onChanged: (_) => _setCoord(),
                ),
              ),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: VTextField(
                  label: 'Longitude',
                  controller: _lng,
                  placeholder: '36.8219',
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  error: _lng.text.isNotEmpty && parseCoord(_lng.text, 180) == null ? 'Between -180 and 180' : null,
                  onChanged: (_) => _setCoord(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.errors[Field.location] ?? 'Copy the pin’s coordinates from any map app.',
            style: VelioText.caption.copyWith(
              color: widget.errors[Field.location] != null ? VelioColors.danger : VelioColors.muted,
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
    );
  }
}
