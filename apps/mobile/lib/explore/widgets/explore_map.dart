// C1's map (S7b FR-003): only activities with spots, so sold-out and started ones leave it. A carousel
// of preview cards sits over its lower edge, one per pin and kept in step with the pins (explore map
// preview FR-003–FR-009): a pin tap scrolls to its card, a swipe pans to its pin.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/components.dart';
import '../bloc/explore_bloc.dart';
import 'map_preview_card.dart';

class ExploreMap extends StatefulWidget {
  const ExploreMap({super.key, required this.state, this.stale = false});
  final ExploreState state;

  /// Offline or reconnecting: spots badges say so.
  final bool stale;

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap> {
  static const _carouselGap = VelioSpace.s3;

  late final PageController _pages = PageController(viewportFraction: 0.86, initialPage: _indexOf(widget.state));
  GoogleMapController? _map;

  /// Set while the carousel animates to a pin's card, so the pages it passes don't select themselves.
  bool _following = false;

  static int _indexOf(ExploreState s) {
    final i = s.open.indexWhere((a) => a.id == s.selected?.id);
    return i < 0 ? 0 : i;
  }

  static LatLng _at(ActivityCard a) => LatLng(a.location.lat.toDouble(), a.location.lng.toDouble());

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// The selection changed (pin, swipe, or the selected one left the map): show its card and pin.
  Future<void> _follow(ExploreState s) async {
    final selected = s.selected;
    if (selected == null) return;
    await _map?.animateCamera(CameraUpdate.newLatLng(_at(selected)));
    if (!mounted) return;
    final i = _indexOf(s);
    if (!_pages.hasClients || _pages.page?.round() == i) return;
    _following = true;
    await _pages.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    _following = false;
  }

  /// Frames every pin (FR-009); one pin keeps the initial zoom.
  Future<void> _frame(List<ActivityCard> open) async {
    if (open.length < 2) return;
    final lats = open.map((a) => a.location.lat.toDouble());
    final lngs = open.map((a) => a.location.lng.toDouble());
    final sw = LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b));
    final ne = LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b));
    if (sw == ne) return;
    await _map?.moveCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 48));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final open = state.open;
    final selected = state.selected;
    final start = selected ?? state.page!.activities.first;
    return BlocListener<ExploreBloc, ExploreState>(
      listenWhen: (a, b) => a.selected?.id != b.selected?.id || _indexOf(a) != _indexOf(b),
      listener: (_, s) => _follow(s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VelioRadius.card),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _at(start), zoom: 12),
                // Keeps the camera's centre, and the framed pins, above the carousel.
                padding: EdgeInsets.only(bottom: open.isEmpty ? 0 : MapPreviewCard.height + _carouselGap),
                onMapCreated: (c) {
                  _map = c;
                  _frame(open);
                },
                markers: {
                  for (final a in open)
                    Marker(
                      markerId: MarkerId(a.id),
                      position: _at(a),
                      consumeTapEvents: true,
                      icon: a.id == selected?.id
                          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                          : BitmapDescriptor.defaultMarker,
                      zIndexInt: a.id == selected?.id ? 1 : 0,
                      onTap: () => context.read<ExploreBloc>().add(ExploreMapSelected(a.id)),
                    ),
                },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              ),
              if (open.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _carouselGap,
                  height: MapPreviewCard.height,
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: open.length,
                    onPageChanged: (i) {
                      if (_following || open[i].id == selected?.id) return;
                      context.read<ExploreBloc>().add(ExploreMapSelected(open[i].id));
                    },
                    itemBuilder: (context, i) {
                      final a = open[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: MapPreviewCard(
                          title: a.title,
                          meta: '${formatWhen(a.startsAt, a.timezone)} · ${a.location.venueName}',
                          summary: a.summary,
                          price: formatMoney(a.priceMinor, a.currency),
                          photoUrl: a.photoUrl,
                          spots: state.spotsOf(a),
                          spotsState: widget.stale
                              ? SpotsState.stale
                              : (state.changed(a) ? SpotsState.changed : SpotsState.live),
                          selected: a.id == selected?.id,
                          onTap: () => context.push('/activities/${a.id}'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
