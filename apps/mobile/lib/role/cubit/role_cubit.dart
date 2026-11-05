// The Booker / Host toggle (S7b FR-001; PRD W1, Rules): it switches the interface, not permissions,
// and is remembered on the device.
import 'package:bloc/bloc.dart';

import '../../domain/role.dart';
import '../../repositories/preferences_repository.dart';

export '../../domain/role.dart';

class RoleCubit extends Cubit<Role> {
  /// [initial] is the saved role, loaded before the first frame.
  RoleCubit({required PreferencesRepository preferencesRepository, required Role initial})
    : _prefs = preferencesRepository,
      super(initial);

  final PreferencesRepository _prefs;

  Future<void> changed(Role role) async {
    emit(role);
    await _prefs.saveRole(role);
  }
}
