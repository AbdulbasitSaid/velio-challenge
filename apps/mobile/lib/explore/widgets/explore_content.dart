// C1's content: the community's header, then its cards as a list or, with native maps, a map of the
// activities that still have spots.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/art.dart';
import '../../ui/cards.dart';
import '../../ui/components.dart';
import '../bloc/explore_bloc.dart';
import 'explore_map.dart';

const mapHint = 'Only activities with spots show. Sold-out and started ones leave the map.';

String countLine(int withSpots, int total) {
  if (total == 0) return 'No upcoming activities';
  if (withSpots == 0) return 'No upcoming activities with spots';
  return withSpots == 1 ? '1 upcoming activity with spots' : '$withSpots upcoming activities with spots';
}

class ExploreContent extends StatelessWidget {
  const ExploreContent({super.key, required this.state, required this.online, required this.maps});
  final ExploreState state;
  final bool online;

  /// Native maps are on and the phone is online: the List / Map toggle shows.
  final bool maps;

  @override
  Widget build(BuildContext context) {
    final page = state.page!;
    final c = page.community;
    final stale = !online || state.reconnecting;
    final open = state.open;
    final showMap = maps && state.showMap;
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
                value: state.showMap,
                options: const {false: 'List', true: 'Map'},
                onChanged: (v) => context.read<ExploreBloc>().add(ExploreViewToggled(v)),
              ),
            ),
          if (showMap) ...[
            ExploreMap(state: state, stale: stale),
            Text(mapHint, style: VelioText.caption.copyWith(color: VelioColors.muted)),
          ] else
            for (final a in page.activities)
              ActivityTile(
                title: a.title,
                meta: '${formatWhen(a.startsAt, a.timezone)} · ${a.location.venueName}',
                photoUrl: a.photoUrl,
                spots: state.spotsOf(a),
                spotsState: stale ? SpotsState.stale : (state.changed(a) ? SpotsState.changed : SpotsState.live),
                onTap: () => context.push('/activities/${a.id}'),
              ),
        ],
      ],
    );
  }
}
