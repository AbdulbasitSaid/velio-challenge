// A pin's preview on the C1 map (explore map preview FR-004): photo, title, "date · venue", the
// description's summary, price and live spots. The whole card opens the activity.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';
import '../../ui/components.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({
    super.key,
    required this.title,
    required this.meta,
    required this.summary,
    required this.price,
    required this.spots,
    this.photoUrl,
    this.spotsState = SpotsState.live,
    this.selected = false,
    this.onTap,
  });
  final String title;
  final String meta;

  /// Hidden when empty.
  final String summary;
  final String price;
  final int spots;
  final String? photoUrl;
  final SpotsState spotsState;

  /// The card of the highlighted pin.
  final bool selected;
  final VoidCallback? onTap;

  static const height = 136.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: title,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: VelioColors.surface,
        borderRadius: BorderRadius.circular(VelioRadius.card),
        border: Border.all(color: selected ? VelioColors.forest : VelioColors.line, width: selected ? 2 : 1),
        boxShadow: VelioShadows.raised,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(VelioRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 96,
                child: Photo(url: photoUrl, small: true, dimmed: spots <= 0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(VelioSpace.s3, VelioSpace.s3, VelioSpace.s3, VelioSpace.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: VelioText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        meta,
                        style: VelioText.caption.copyWith(color: VelioColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(summary, style: VelioText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Text(price, style: VelioText.bodyStrong, maxLines: 1),
                          const SizedBox(width: VelioSpace.s2),
                          // Narrow phones: the badge shrinks rather than overflow.
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SpotsBadge(spots: spots, state: spotsState),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
