// One of H3's cards: thumbnail, title, when, "n of cap booked" and the status chip.
import 'package:flutter/material.dart';
import 'package:velio_api/velio_api.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';

/// The card's status chip, as the approved canvas draws it (web `hostRow`).
({String status, ChipTone tone}) hostRow(HostActivityItem a, {required bool past}) {
  if (!past) {
    if (a.bookedCount == 0) return (status: 'No bookings yet', tone: ChipTone.neutral);
    return (status: spotsLabel(a.spotsLeft), tone: a.spotsLeft <= 0 ? ChipTone.forest : ChipTone.lime);
  }
  if (a.bookedCount == 0) return (status: 'No bookings', tone: ChipTone.neutral);
  if (a.markedCount == 0) return (status: 'Mark attendance', tone: ChipTone.danger);
  return (status: '${a.attendedCount} attended', tone: ChipTone.neutral);
}

class HostActivityCard extends StatelessWidget {
  const HostActivityCard({super.key, required this.activity, required this.past, required this.onTap});
  final HostActivityItem activity;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final row = hostRow(a, past: past);
    return Material(
      color: VelioColors.surface,
      borderRadius: BorderRadius.circular(VelioRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(VelioRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                        Text(a.title, style: VelioText.bodyStrong),
                        Text(
                          formatWhen(a.startsAt, a.timezone),
                          style: VelioText.caption.copyWith(color: VelioColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VelioSpace.s2,
                runSpacing: VelioSpace.s2,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${a.bookedCount}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' of ${a.capacity} booked'),
                      ],
                    ),
                    style: VelioText.body.copyWith(fontSize: 14),
                  ),
                  VChip(row.status, tone: row.tone),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
