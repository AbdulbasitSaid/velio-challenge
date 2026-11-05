// A field's error under it, announced as it appears.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';

class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: VIcon('alert', size: 16, color: VelioColors.danger),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: VelioText.caption.copyWith(color: VelioColors.danger)),
        ),
      ],
    ),
  );
}
