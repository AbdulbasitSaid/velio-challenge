import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/components.dart';

/// "Claiming as {Name} / {masked contact} · saved on this phone / Not you?".
class ClaimingAs extends StatelessWidget {
  const ClaimingAs({super.key, required this.displayName, required this.maskedContact, this.onNotYou});
  final String displayName;
  final String maskedContact;

  /// Null while a claim is in flight.
  final VoidCallback? onNotYou;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 14),
      decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.card)),
      child: Row(
        children: [
          Avatar(name: displayName, size: 44),
          const SizedBox(width: VelioSpace.s3),
          // "Not you?" moves under the name when large text leaves no room beside it.
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: VelioSpace.s2,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claiming as $displayName', style: VelioText.bodyStrong),
                    Text(
                      '$maskedContact · saved on this phone',
                      style: VelioText.caption.copyWith(color: VelioColors.muted),
                    ),
                  ],
                ),
                VButton('Not you?', variant: ButtonVariant.quiet, small: true, onPressed: onNotYou),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
