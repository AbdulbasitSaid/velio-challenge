// The native map with the pin fixed at its centre: dragging the map moves the pin.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';

class PinMap extends StatefulWidget {
  const PinMap({super.key, required this.lat, required this.lng, required this.onCreated, required this.onStopped});
  final double lat;
  final double lng;
  final ValueChanged<GoogleMapController> onCreated;

  /// Where the map's centre came to rest.
  final ValueChanged<LatLng> onStopped;

  @override
  State<PinMap> createState() => _PinMapState();
}

class _PinMapState extends State<PinMap> {
  /// Where the map is moving to; reported when it stops.
  LatLng? _pending;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(VelioRadius.card),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            label: 'Map. Drag it to move the pin.',
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(widget.lat, widget.lng), zoom: 16),
              onMapCreated: widget.onCreated,
              onCameraMove: (p) => _pending = p.target,
              onCameraIdle: () {
                final t = _pending;
                if (t == null) return;
                _pending = null;
                widget.onStopped(t);
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
  );
}
