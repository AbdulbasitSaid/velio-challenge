import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

/// The destructive confirm (`host.remove.confirm`).
class DangerButton extends StatelessWidget {
  const DangerButton(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: VelioColors.danger,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VelioSize.buttonHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s6, vertical: VelioSpace.s2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: VelioText.button.copyWith(color: VelioColors.surface),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
