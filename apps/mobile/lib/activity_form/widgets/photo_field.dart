// H2's one photo: the current or uploaded image with Change photo, or the empty prompt.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';
import '../../ui/components.dart';
import 'field_error.dart';

class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.preview,
    required this.url,
    required this.busy,
    required this.error,
    required this.onPick,
  });

  /// The photo just uploaded, before the page reloads.
  final Uint8List? preview;
  final String? url;
  final bool busy;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final has = preview != null || url != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (has)
          ClipRRect(
            borderRadius: BorderRadius.circular(VelioRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (preview != null)
                    Image.memory(preview!, fit: BoxFit.cover, gaplessPlayback: true)
                  else
                    Photo(url: url),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: VelioColors.surface,
                      shape: const StadiumBorder(),
                      child: VButton(
                        'Change photo',
                        small: true,
                        variant: ButtonVariant.quiet,
                        loading: busy,
                        onPressed: onPick,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s5, vertical: 28),
            decoration: BoxDecoration(
              color: VelioColors.surface,
              borderRadius: BorderRadius.circular(VelioRadius.card),
              border: Border.all(color: error != null ? VelioColors.danger : VelioColors.fieldBorder, width: 2),
            ),
            child: Column(
              children: [
                Text('Add one photo', style: VelioText.bodyStrong),
                const SizedBox(height: VelioSpace.s2),
                Text(
                  'It leads your activity page and every invite link.',
                  textAlign: TextAlign.center,
                  style: VelioText.body.copyWith(fontSize: 14, color: VelioColors.muted),
                ),
                const SizedBox(height: VelioSpace.s3),
                VButton(
                  busy ? 'Uploading…' : 'Choose a photo',
                  variant: ButtonVariant.secondary,
                  small: true,
                  loading: busy,
                  onPressed: onPick,
                ),
              ],
            ),
          ),
        if (error != null) ...[const SizedBox(height: 6), FieldError(error!)],
      ],
    );
  }
}
