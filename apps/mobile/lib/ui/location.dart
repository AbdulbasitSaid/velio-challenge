// Location block (Maps spec FR-009, FR-011–FR-013): venue, address, meeting point, a native map with
// one marker, and directions. Without a Maps key, offline, or if the map fails, the address and
// directions still show and nothing else is affected (PRD A7, S7 FR-018).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../app/config.dart';
import 'art.dart';
import 'components.dart';

class Place {
  const Place({
    required this.venue,
    required this.address,
    required this.lat,
    required this.lng,
    required this.directionsUrl,
    this.meetingPoint,
  });
  final String venue;
  final String address;
  final double lat;
  final double lng;
  final String directionsUrl;
  final String? meetingPoint;
}

class LocationBlock extends StatelessWidget {
  const LocationBlock({super.key, required this.place, this.offline = false, this.aspectRatio = 4 / 3});
  final Place place;
  final bool offline;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    final maps = config.mapsEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Where'),
        const SizedBox(height: VelioSpace.s3),
        if (offline)
          MapNote(aspectRatio: aspectRatio, text: 'Map unavailable offline')
        else if (maps)
          ClipRRect(
            borderRadius: BorderRadius.circular(VelioRadius.card),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Semantics(
                label: 'Map showing ${place.venue}',
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: LatLng(place.lat, place.lng), zoom: 15),
                  markers: {Marker(markerId: const MarkerId('venue'), position: LatLng(place.lat, place.lng))},
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ),
        if (offline || maps) const SizedBox(height: VelioSpace.s3),
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 1), child: VIcon('pin')),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.venue, style: VelioText.bodyStrong),
                    Text(
                      place.address,
                      style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14, color: VelioColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (place.meetingPoint != null) ...[
          const SizedBox(height: VelioSpace.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s3, vertical: 10),
            decoration: BoxDecoration(color: VelioColors.sun, borderRadius: BorderRadius.circular(VelioRadius.small)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VIcon('flag', size: 18),
                const SizedBox(width: VelioSpace.s2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Meeting point: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: place.meetingPoint),
                      ],
                    ),
                    style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: VelioSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: VButton(
            'Get directions',
            icon: 'directions',
            variant: ButtonVariant.secondary,
            small: true,
            onPressed: () => openDirections(context, place, ios: config.platform == 'ios'),
          ),
        ),
      ],
    );
  }
}

class MapNote extends StatelessWidget {
  const MapNote({super.key, required this.aspectRatio, required this.text});
  final double aspectRatio;
  final String text;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: Container(
      decoration: BoxDecoration(color: VelioColors.mapLand, borderRadius: BorderRadius.circular(VelioRadius.card)),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VIcon('map', color: VelioColors.muted),
          const SizedBox(width: VelioSpace.s2),
          Flexible(
            child: Text(text, style: VelioText.bodyStrong.copyWith(color: VelioColors.muted)),
          ),
        ],
      ),
    ),
  );
}

/// Android: the API's Google Maps directions link (opens the Maps app). iOS: Apple Maps or Google
/// Maps, as G4 draws it (Maps FR-011).
Future<void> openDirections(BuildContext context, Place place, {required bool ios}) async {
  final google = Uri.parse(place.directionsUrl);
  if (!ios) {
    await launchUrl(google, mode: LaunchMode.externalApplication);
    return;
  }
  final apple = Uri.https('maps.apple.com', '/', {'daddr': '${place.lat},${place.lng}', 'q': place.venue});
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: VelioColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VelioRadius.hero))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s3, VelioSpace.s5, VelioSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Open directions in', style: VelioText.subheading),
            Text(
              '${place.venue}, ${place.address}',
              style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
            ),
            const SizedBox(height: VelioSpace.s3),
            VButton(
              'Apple Maps',
              variant: ButtonVariant.secondary,
              block: true,
              onPressed: () {
                Navigator.pop(sheet);
                launchUrl(apple, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: VelioSpace.s3),
            VButton(
              'Google Maps',
              variant: ButtonVariant.secondary,
              block: true,
              onPressed: () {
                Navigator.pop(sheet);
                launchUrl(google, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: VelioSpace.s2),
            VButton('Cancel', variant: ButtonVariant.quiet, block: true, onPressed: () => Navigator.pop(sheet)),
          ],
        ),
      ),
    ),
  );
}

/// A wide photo or scene art with the spots badge in the corner (G1, G2, G5).
class HeroPhoto extends StatelessWidget {
  const HeroPhoto({super.key, required this.url, this.badge, this.dimmed = false, this.aspectRatio = 16 / 10});
  final String? url;
  final Widget? badge;
  final bool dimmed;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(VelioRadius.hero),
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Phones take the 640 px file: the invite's 3G budget (S6 D4).
          Photo(url: url, small: true, dimmed: dimmed),
          if (badge != null) Positioned(left: 12, bottom: 12, child: badge!),
        ],
      ),
    ),
  );
}
