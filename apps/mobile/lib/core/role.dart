// The Booker / Host toggle (S7b FR-001; PRD W1, Rules): it switches the interface, not permissions,
// and is remembered on the device.
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Role { booker, host }

const _roleKey = 'velio.role';

/// main.dart overrides it with the saved role.
final roleProvider = StateProvider<Role>((ref) => Role.booker);

Future<Role> loadRole(SharedPreferencesAsync prefs) async =>
    await prefs.getString(_roleKey) == 'host' ? Role.host : Role.booker;

Future<void> saveRole(SharedPreferencesAsync prefs, Role role) => prefs.setString(_roleKey, role.name);
