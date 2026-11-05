// Identity on the device (S7 §4.4): a device ID and the session token in platform secure storage
// (Keychain, Android Keystore; SEC-001), and for "Claiming as" only the display name and a masked
// contact (the raw contact is never stored: SEC-002).
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// The secure store, behind an interface so tests use memory.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecretStore implements SecretStore {
  const PlatformSecretStore();
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class LocalProfile {
  const LocalProfile({required this.userId, required this.displayName, required this.maskedContact});
  final String userId;
  final String displayName;
  final String maskedContact;

  Map<String, Object> toJson() => {'userId': userId, 'displayName': displayName, 'maskedContact': maskedContact};
  static LocalProfile? fromJson(Object? j) => j is Map<String, dynamic>
      ? LocalProfile(
          userId: j['userId'] as String,
          displayName: j['displayName'] as String,
          maskedContact: j['maskedContact'] as String,
        )
      : null;
}

class Identity {
  Identity(this._secrets, this._prefs);
  final SecretStore _secrets;
  final SharedPreferencesAsync _prefs;

  static const _deviceKey = 'velio.device_id';
  static const _tokenKey = 'velio.token';
  static const _profileKey = 'velio.profile';
  static const _installedKey = 'velio.installed';

  String? _deviceId;
  String? _token;
  LocalProfile? _profile;

  String get deviceId => _deviceId!;
  String? get token => _token;
  LocalProfile? get profile => _token == null ? null : _profile;
  bool get signedIn => _token != null;

  /// Loads the stored values, creating the device ID on first launch.
  Future<void> load() async {
    _deviceId = await _secrets.read(_deviceKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _secrets.write(_deviceKey, _deviceId!);
    }
    // iOS keeps keychain items after the app is deleted, but not preferences. A token from before a
    // reinstall would sign in someone who can't see who they are ("Claiming as" needs the profile),
    // so the first launch after an install starts signed out.
    if (await _prefs.getBool(_installedKey) != true) {
      await _secrets.delete(_tokenKey);
      await _prefs.setBool(_installedKey, true);
    }
    _token = await _secrets.read(_tokenKey);
    final raw = await _prefs.getString(_profileKey);
    _profile = raw == null ? null : LocalProfile.fromJson(jsonDecode(raw));
  }

  Future<void> signIn(String token, LocalProfile profile) async {
    _token = token;
    _profile = profile;
    await _secrets.write(_tokenKey, token);
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  /// A `401`, or "Not you?": forget the session and the local profile.
  Future<void> signOut() async {
    _token = null;
    _profile = null;
    await _secrets.delete(_tokenKey);
    await _prefs.remove(_profileKey);
  }
}
