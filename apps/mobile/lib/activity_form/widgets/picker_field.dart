import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';

import 'field_error.dart';

/// A field that opens a picker: date, time, zone, community. Read-only when [onTap] is null.
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, this.value, this.placeholder, this.help, this.error, this.onTap});
  final String label;
  final String? value;
  final String? placeholder;
  final String? help;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 18 / 14)),
        const SizedBox(height: 6),
        Semantics(
          button: enabled,
          label: '$label, ${value ?? placeholder ?? ''}',
          excludeSemantics: true,
          child: Material(
            color: enabled ? VelioColors.surface : VelioColors.disabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VelioRadius.field),
              side: BorderSide(
                color: error != null ? VelioColors.danger : (enabled ? VelioColors.fieldBorder : VelioColors.disabled),
                width: error != null ? 2 : 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(VelioRadius.field),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value ?? placeholder ?? '',
                          style: VelioText.body.copyWith(
                            fontSize: 16,
                            color: value == null ? VelioColors.muted : VelioColors.ink,
                          ),
                        ),
                      ),
                      VIcon(enabled ? 'chevron' : 'lock', size: 18, color: VelioColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          FieldError(error!),
        ] else if (help != null) ...[
          const SizedBox(height: 6),
          Text(help!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
        ],
      ],
    );
  }
}
