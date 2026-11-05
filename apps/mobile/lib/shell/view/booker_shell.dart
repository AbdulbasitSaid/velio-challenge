// The booker's shell (S7b §4.1, FR-002): the bottom bar (Explore, Code, My plans). Host screens have
// no bottom bar.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../ui/art.dart';

class BookerShell extends StatelessWidget {
  const BookerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: MediaQuery.withClampedTextScaling(
      // The bar's height is fixed, so its labels stop growing at 150%, as the app bar's do.
      maxScaleFactor: 1.5,
      child: NavigationBar(
        backgroundColor: VelioColors.surface,
        indicatorColor: VelioColors.lime,
        selectedIndex: shell.currentIndex,
        labelTextStyle: WidgetStatePropertyAll(VelioText.caption.copyWith(fontWeight: FontWeight.w700)),
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: VIcon('map'), label: 'Explore'),
          NavigationDestination(icon: VIcon('ticket'), label: 'Code'),
          NavigationDestination(icon: VIcon('calendar'), label: 'My plans'),
        ],
      ),
    ),
  );
}
