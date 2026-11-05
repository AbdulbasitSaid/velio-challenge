// The Booker / Host toggle (S7b FR-001, FR-002) for top-level screens: switches the interface and
// goes to that role's home.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../role/cubit/role_cubit.dart';
import '../../ui/components.dart';

class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key});

  @override
  Widget build(BuildContext context) => Segmented<Role>(
    label: 'Use Velio as',
    value: context.watch<RoleCubit>().state,
    options: const {Role.booker: 'Booker', Role.host: 'Host'},
    onChanged: (role) {
      context.read<RoleCubit>().changed(role);
      context.go(role == Role.host ? '/host' : '/');
    },
  );
}
