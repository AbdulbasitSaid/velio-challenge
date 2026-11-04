// Cards for the booker and host screens (S7b), from the web's cards.tsx and invite/parts.tsx: the
// compact activity card (C1, H2 preview), the host card (B1) and the attendance row (H1).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import 'art.dart';
import 'components.dart';

/// The compact activity card: photo with the spots badge, title, and "date · place".
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.title,
    required this.meta,
    this.photoUrl,
    this.photoBytes,
    this.spots,
    this.spotsState = SpotsState.live,
    this.chip,
    this.lines = const [],
    this.onTap,
  });
  final String title;
  final String meta;
  final String? photoUrl;

  /// A local preview (H2) instead of [photoUrl].
  final Uint8List? photoBytes;
  final int? spots;
  final SpotsState spotsState;
  final String? chip;

  /// Extra rows under the meta line (the H2 preview's price and host).
  final List<String> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: VelioColors.surface,
    borderRadius: BorderRadius.circular(VelioRadius.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photoBytes != null)
                  Image.memory(photoBytes!, fit: BoxFit.cover, gaplessPlayback: true)
                else
                  Photo(url: photoUrl, small: true, dimmed: spots != null && spots! <= 0),
                if (chip != null) Positioned(left: 12, top: 12, child: VChip(chip!, tone: ChipTone.outline)),
                if (spots != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: SpotsBadge(spots: spots!, state: spotsState),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(VelioSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VelioText.subheading),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14, color: VelioColors.muted),
                ),
                for (final l in lines) ...[
                  const SizedBox(height: 4),
                  Text(l, style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Hosted by {Host}", the community and a link to the profile (B1).
class HostCard extends StatelessWidget {
  const HostCard({super.key, required this.name, required this.seed, required this.community, this.onProfile});
  final String name;
  final String seed;
  final String community;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 14),
    decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.card)),
    child: Row(
      children: [
        Avatar(name: name, seed: seed, size: 44),
        const SizedBox(width: VelioSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hosted by $name', style: VelioText.bodyStrong),
              Text(community, style: VelioText.caption.copyWith(color: VelioColors.muted)),
            ],
          ),
        ),
        if (onProfile != null) VButton('Profile', variant: ButtonVariant.quiet, small: true, onPressed: onProfile),
      ],
    ),
  );
}

enum Mark { attended, noShow }

/// An H1 row: avatar, name, "ref · booked", the source chip, then Remove before the start or the
/// Attended / No-show pair after it. Removed rows are dimmed and take no action.
class AttendanceRow extends StatelessWidget {
  const AttendanceRow({
    super.key,
    required this.name,
    required this.seed,
    required this.meta,
    required this.source,
    required this.sourceTone,
    required this.after,
    this.mark,
    this.isNew = false,
    this.removed = false,
    this.onRemove,
    this.onMark,
  });
  final String name;
  final String seed;
  final String meta;
  final String source;
  final ChipTone sourceTone;
  final bool after;
  final Mark? mark;
  final bool isNew;
  final bool removed;
  final VoidCallback? onRemove;
  final ValueChanged<Mark>? onMark;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: removed ? 0.55 : 1,
    child: Container(
      color: isNew ? VelioColors.lime.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Avatar(name: name, seed: seed),
                const SizedBox(width: VelioSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: VelioText.bodyStrong),
                      Text(meta, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: VelioSpace.s2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: VChip(source, tone: sourceTone),
                ),
              ],
            ),
          ),
          if (!removed) ...[
            const SizedBox(height: VelioSpace.s2),
            if (!after)
              Align(
                alignment: Alignment.centerRight,
                child: VButton('Remove', variant: ButtonVariant.quiet, small: true, onPressed: onRemove),
              )
            else
              Semantics(
                container: true,
                label: 'Attendance for $name',
                child: Row(
                  children: [
                    Expanded(
                      child: _MarkButton(
                        'Attended',
                        selected: mark == Mark.attended,
                        onTap: onMark == null ? null : () => onMark!(Mark.attended),
                      ),
                    ),
                    const SizedBox(width: VelioSpace.s2),
                    Expanded(
                      child: _MarkButton(
                        'No-show',
                        selected: mark == Mark.noShow,
                        danger: true,
                        onTap: onMark == null ? null : () => onMark!(Mark.noShow),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class _MarkButton extends StatelessWidget {
  const _MarkButton(this.label, {required this.selected, this.danger = false, this.onTap});
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = !selected ? VelioColors.surface : (danger ? VelioColors.danger : VelioColors.forest);
    final fg = !selected ? VelioColors.forest : (danger ? VelioColors.surface : VelioColors.lime);
    return Semantics(
      button: true,
      toggled: selected,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(color: danger && !selected ? VelioColors.fieldBorder : VelioColors.forest, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VelioSize.touchMin),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s2, vertical: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: VelioText.bodyStrong.copyWith(fontSize: 14, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
