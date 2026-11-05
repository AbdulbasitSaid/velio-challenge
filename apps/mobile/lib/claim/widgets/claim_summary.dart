import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/art.dart';

/// What's being claimed: photo, title and when.
class ClaimSummary extends StatelessWidget {
  const ClaimSummary({super.key, required this.activity});
  final PublicActivity activity;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Container(
      padding: const EdgeInsets.all(VelioSpace.s3),
      decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.card)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VelioRadius.small),
            child: SizedBox.square(dimension: 56, child: Photo(url: a.photoUrl, small: true)),
          ),
          const SizedBox(width: VelioSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: VelioText.bodyStrong.copyWith(fontSize: 16)),
                Text(
                  '${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)}',
                  style: VelioText.caption.copyWith(color: VelioColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
