// The searchable list of time zones.
import 'package:flutter/material.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../domain/host_form.dart';
import '../../ui/components.dart';

class ZoneSheet extends StatefulWidget {
  const ZoneSheet({super.key});
  @override
  State<ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends State<ZoneSheet> {
  final _all = timeZoneNames();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase().replaceAll(' ', '_');
    final shown = q.isEmpty ? _all : _all.where((z) => z.toLowerCase().contains(q)).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s5, VelioSpace.s5, VelioSpace.s2),
              child: VTextField(
                label: 'Time zone',
                placeholder: 'Search, e.g. Nairobi',
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(shown[i], style: VelioText.body),
                  onTap: () => Navigator.pop(context, shown[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
