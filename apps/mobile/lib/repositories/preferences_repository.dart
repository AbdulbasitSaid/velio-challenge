// Settings kept on the device: the Booker / Host role (S7b FR-001).
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/role.dart';

class PreferencesRepository {
  PreferencesRepository(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const _roleKey = 'velio.role';

  Future<Role> loadRole() async => await _prefs.getString(_roleKey) == 'host' ? Role.host : Role.booker;

  Future<void> saveRole(Role role) => _prefs.setString(_roleKey, role.name);
}
