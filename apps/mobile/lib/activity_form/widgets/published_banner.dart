// "Published. … is live in …" straight after Publish, with the next places to go.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';
import '../../ui/components.dart';

class PublishedBanner extends StatelessWidget {
  const PublishedBanner({super.key, required this.title, required this.activity});
  final String title;
  final PublicActivity activity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(VelioSpace.s4),
    decoration: BoxDecoration(color: VelioColors.lime, borderRadius: BorderRadius.circular(VelioRadius.card)),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VIcon('check'),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: Text(
                  'Published. $title is live in ${activity.community.name}.',
                  style: VelioText.bodyStrong.copyWith(color: VelioColors.forest),
                ),
              ),
            ],
          ),
          const SizedBox(height: VelioSpace.s3),
          VButton(
            'Open live attendance',
            variant: ButtonVariant.secondary,
            small: true,
            block: true,
            onPressed: () => context.push('/host/${activity.id}/attendance'),
          ),
          VButton(
            'View the page',
            variant: ButtonVariant.quiet,
            small: true,
            block: true,
            onPressed: () => context.push('/activities/${activity.id}'),
          ),
        ],
      ),
    ),
  );
}
