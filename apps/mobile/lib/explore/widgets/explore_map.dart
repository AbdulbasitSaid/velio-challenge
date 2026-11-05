// C1's map (S7b FR-003): only activities with spots, so sold-out and started ones leave it.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../bloc/explore_bloc.dart';

class ExploreMap extends StatelessWidget {
  const ExploreMap({super.key, required this.state});
  final ExploreState state;

  @override
  Widget build(BuildContext context) {
    final page = state.page!;
    final open = state.open;
    return ClipRRect(
      borderRadius: BorderRadius.circular(VelioRadius.card),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: open.isEmpty
                ? LatLng(page.activities.first.location.lat.toDouble(), page.activities.first.location.lng.toDouble())
                : LatLng(open.first.location.lat.toDouble(), open.first.location.lng.toDouble()),
            zoom: 9,
          ),
          markers: {
            for (final a in open)
              Marker(
                markerId: MarkerId(a.id),
                position: LatLng(a.location.lat.toDouble(), a.location.lng.toDouble()),
                infoWindow: InfoWindow(
                  title: a.title,
                  snippet: '${spotsLabel(state.spotsOf(a))} · View activity',
                  onTap: () => context.push('/activities/${a.id}'),
                ),
              ),
          },
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
