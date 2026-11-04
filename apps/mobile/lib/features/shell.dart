// The app shell (S7b §4.1, FR-001, FR-002): the Booker / Host toggle for top-level screens, and the
// booker's bottom bar (Explore, Code, My plans). Host screens have no bottom bar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/providers.dart';
import '../core/role.dart';
import '../ui/art.dart';
import '../ui/components.dart';

class RoleToggle extends ConsumerWidget {
  const RoleToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Segmented<Role>(
    label: 'Use Velio as',
    value: ref.watch(roleProvider),
    options: const {Role.booker: 'Booker', Role.host: 'Host'},
    onChanged: (role) {
      ref.read(roleProvider.notifier).state = role;
      saveRole(ref.read(prefsProvider), role);
      context.go(role == Role.host ? '/host' : '/');
    },
  );
}

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
