// "Remove …?" (`host.remove.confirm`): always asked before a removal. Pops true to remove.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/format.dart';
import '../../ui/components.dart';
import 'danger_button.dart';

class RemoveGuestSheet extends StatelessWidget {
  const RemoveGuestSheet({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s5, VelioSpace.s5, VelioSpace.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Remove $name?', style: VelioText.heading.copyWith(fontSize: 20))),
          const SizedBox(height: VelioSpace.s2),
          Text(
            'Their spot opens to whoever books next, and they’ll see that you removed them.',
            style: VelioText.body.copyWith(color: VelioColors.muted),
          ),
          const SizedBox(height: VelioSpace.s4),
          DangerButton('Remove ${firstName(name)}', onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: VelioSpace.s2),
          VButton('Keep', variant: ButtonVariant.quiet, block: true, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    ),
  );
}
