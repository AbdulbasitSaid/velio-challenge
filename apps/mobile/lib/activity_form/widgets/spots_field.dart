import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/host_form.dart';
import '../../ui/art.dart';
import 'field_error.dart';

/// "Total spots" with − and + (never below the people booked).
class SpotsField extends StatelessWidget {
  const SpotsField({
    super.key,
    required this.controller,
    required this.value,
    required this.floor,
    required this.booked,
    required this.error,
    required this.onChanged,
    required this.onTyped,
  });
  final TextEditingController controller;
  final int? value;
  final int floor;
  final int booked;
  final String? error;
  final ValueChanged<int?> onChanged;
  final ValueChanged<int?> onTyped;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total spots', style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 18 / 14)),
        const SizedBox(height: 6),
        Row(
          children: [
            SpotsStepButton(
              'minus',
              'One fewer spot',
              v != null && v > floor ? () => onChanged(v - 1 < floor ? floor : v - 1) : null,
            ),
            const SizedBox(width: VelioSpace.s2),
            SizedBox(
              width: 96,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: VelioText.bodyStrong.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VelioColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: VelioSpace.s2, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VelioRadius.field),
                    borderSide: BorderSide(
                      color: error != null ? VelioColors.danger : VelioColors.fieldBorder,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VelioRadius.field),
                    borderSide: const BorderSide(color: VelioColors.forest, width: 2),
                  ),
                ),
                onChanged: (raw) => onTyped(int.tryParse(raw)),
              ),
            ),
            const SizedBox(width: VelioSpace.s2),
            SpotsStepButton(
              'plus',
              'One more spot',
              v != null && v >= capacityMax
                  ? null
                  : () => onChanged(v == null ? floor : (v + 1 < floor ? floor : v + 1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (error != null)
          FieldError(error!)
        else
          Text(spotsHelp(booked), style: VelioText.caption.copyWith(color: VelioColors.muted)),
      ],
    );
  }
}

/// − or + beside the spots field; disabled when [onTap] is null.
class SpotsStepButton extends StatelessWidget {
  const SpotsStepButton(this.icon, this.label, this.onTap, {super.key});
  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: VelioColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: onTap == null ? VelioColors.disabled : VelioColors.fieldBorder, width: 1.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: VelioSize.touchMin,
          child: Center(child: VIcon(icon, color: onTap == null ? VelioColors.muted : VelioColors.forest)),
        ),
      ),
    ),
  );
}
