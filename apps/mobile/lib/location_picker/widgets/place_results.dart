// Places' suggestions under the search field, with Google's attribution.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';
import '../../ui/components.dart';
import '../bloc/location_picker_bloc.dart' show PlaceSuggestion;

class PlaceResults extends StatelessWidget {
  const PlaceResults({super.key, required this.results, required this.onPicked});
  final List<PlaceSuggestion> results;
  final ValueChanged<PlaceSuggestion> onPicked;

  @override
  Widget build(BuildContext context) => VList([
    for (final r in results)
      InkWell(
        onTap: () => onPicked(r),
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
                      if (r.sub.isNotEmpty) Text(r.sub, style: VelioText.caption.copyWith(color: VelioColors.muted)),
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
  ]);
}
