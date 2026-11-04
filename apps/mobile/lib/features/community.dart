// C1 community (S7b FR-003; web community-live.tsx): cover, name, blurb, the count line and the list
// with live spots. With native maps on, a List / Map toggle; the map keeps only activities with spots,
// so sold-out and started ones leave it. Explore (no slug) opens the first community, as web `/` does.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/live.dart';
import '../core/online.dart';
import '../core/providers.dart';
import '../core/realtime.dart';
import '../ui/art.dart';
import '../ui/cards.dart';
import '../ui/components.dart';
import 'errors.dart';
import 'shell.dart';

const mapHint = 'Only activities with spots show. Sold-out and started ones leave the map.';

String countLine(int withSpots, int total) {
  if (total == 0) return 'No upcoming activities';
  if (withSpots == 0) return 'No upcoming activities with spots';
  return withSpots == 1 ? '1 upcoming activity with spots' : '$withSpots upcoming activities with spots';
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key, this.slug});

  /// Null on the Explore tab: the first community.
  final String? slug;

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityState();
}

class _CommunityState extends ConsumerState<CommunityScreen> {
  CommunityPage? _page;
  ApiException? _error;
  bool _none = false;
  bool _map = false;
  LiveCounts? _live;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _live?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ref.read(apiProvider);
    try {
      var slug = widget.slug;
      if (slug == null) {
        final list = await api.communities();
        if (list.communities.isEmpty) {
          if (mounted) setState(() => _none = true);
          return;
        }
        slug = list.communities.first.slug;
      }
      final page = await api.community(slug);
      if (!mounted) return;
      setState(() {
        _page = page;
        _error = null;
      });
      final live = _live;
      if (live == null) {
        _live = LiveCounts(
          realtime: ref.read(realtimeProvider),
          initial: {for (final a in page.activities) a.id: (spotsLeft: a.spotsLeft, version: a.version)},
          refresh: _refresh,
        )..addListener(() => mounted ? setState(() {}) : null);
      } else {
        for (final a in page.activities) {
          live.apply(a.id, a.spotsLeft, a.version);
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _refresh() async {
    final slug = _page?.community.slug;
    if (slug == null) return;
    final page = await ref.read(apiProvider).community(slug);
    for (final a in page.activities) {
      _live?.apply(a.id, a.spotsLeft, a.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.slug == null;
    final appBar = tab
        ? const VAppBar(wordmark: true, trailing: RoleToggle())
        : VAppBar(
            leading: VIconButton(
              'back',
              label: 'Back',
              onPressed: () => context.canPop() ? context.pop() : context.go('/explore'),
            ),
            title: _page?.community.name ?? 'Community',
          );
    final err = _error;
    if (_page == null && err != null) {
      final notFound = err.status == 404 || err.status == 400;
      return Scaffold(
        appBar: tab ? appBar : null,
        body: ErrorScreen(
          kind: notFound ? ErrorKind.notFound : (err.network ? ErrorKind.offline : ErrorKind.server),
          onRetry: notFound
              ? null
              : () {
                  setState(() => _error = null);
                  _load();
                },
        ),
      );
    }
    final page = _page;
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: _none
            ? const ScreenBody(
                children: [EmptyState(icon: 'calendar', title: 'No communities yet.', body: 'Check back soon.')],
              )
            : page == null
            ? const _CommunitySkeleton()
            : RefreshIndicator(onRefresh: _load, child: _body(context, page)),
      ),
    );
  }

  Widget _body(BuildContext context, CommunityPage page) {
    final c = page.community;
    final live = _live;
    final stale = !isOnline(ref) || live?.status == RealtimeStatus.reconnecting;
    int spotsOf(ActivityCard a) => live?.spotsOf(a.id) ?? a.spotsLeft;
    SpotsState stateOf(ActivityCard a) =>
        stale ? SpotsState.stale : ((live?.changed(a.id) ?? false) ? SpotsState.changed : SpotsState.live);
    final open = page.activities.where((a) => a.status != ActivityCardStatusEnum.started && spotsOf(a) > 0).toList();
    final maps = ref.watch(mapsEnabledProvider) && isOnline(ref);
    final showMap = maps && _map;

    return ScreenBody(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(VelioRadius.hero),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: c.coverPhotoUrl == null
                ? const PhotoArt(scene: Scene.savanna)
                : Photo(url: c.coverPhotoUrl, scene: Scene.savanna),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(c.name, style: VelioText.title)),
            const SizedBox(height: 6),
            Text(c.blurb, style: VelioText.body.copyWith(color: VelioColors.muted)),
            const SizedBox(height: 6),
            Text(
              countLine(open.length, page.activities.length),
              style: VelioText.bodyStrong.copyWith(fontSize: 14, color: VelioColors.forest),
            ),
          ],
        ),
        if (page.activities.isEmpty)
          const EmptyState(
            icon: 'calendar',
            title: 'Nothing coming up right now',
            body: 'Activities with spots show here as soon as a host publishes one.',
          )
        else ...[
          if (maps)
            Align(
              alignment: Alignment.centerLeft,
              child: Segmented<bool>(
                label: 'View',
                value: _map,
                options: const {false: 'List', true: 'Map'},
                onChanged: (v) => setState(() => _map = v),
              ),
            ),
          if (showMap) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(VelioRadius.card),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: open.isEmpty
                        ? LatLng(
                            page.activities.first.location.lat.toDouble(),
                            page.activities.first.location.lng.toDouble(),
                          )
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
                          snippet: '${spotsLabel(spotsOf(a))} · View activity',
                          onTap: () => context.push('/activities/${a.id}'),
                        ),
                      ),
                  },
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            Text(mapHint, style: VelioText.caption.copyWith(color: VelioColors.muted)),
          ] else
            for (final a in page.activities)
              ActivityTile(
                title: a.title,
                meta: '${formatWhen(a.startsAt, a.timezone)} · ${a.location.venueName}',
                photoUrl: a.photoUrl,
                spots: spotsOf(a),
                spotsState: stateOf(a),
                onTap: () => context.push('/activities/${a.id}'),
              ),
        ],
      ],
    );
  }
}

class _CommunitySkeleton extends StatelessWidget {
  const _CommunitySkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading the community',
    child: const ScreenBody(
      gap: VelioSpace.s4,
      children: [
        Skeleton(height: 190, radius: VelioRadius.hero),
        Skeleton(height: 30, width: 220),
        Skeleton(height: 40),
        Skeleton(height: 260, radius: VelioRadius.card),
      ],
    ),
  );
}
