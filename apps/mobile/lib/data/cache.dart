// Offline cache (PRD M2, S7 §4.8): the last viewed invite and the last My plans list, as JSON with
// their fetch time, written after each successful fetch. Nothing is ever queued: a claim needs a
// live request.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:velio_api/velio_api.dart';

class Cached<T> {
  const Cached(this.value, this.fetchedAt);
  final T value;
  final DateTime fetchedAt;
}

class OfflineCache {
  OfflineCache(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const _inviteKey = 'velio.cache.invite';
  static const _plansKey = 'velio.cache.my_plans';

  Future<void> saveInvite(InviteView view, DateTime at) => _save(_inviteKey, view.toJson(), at);

  /// The cached invite, if it's the one asked for.
  Future<Cached<InviteView>?> invite(String code) async {
    final c = await _load(_inviteKey, InviteView.fromJson);
    return c != null && c.value.code == code ? c : null;
  }

  Future<void> saveMyPlans(MyPlans plans, DateTime at) => _save(_plansKey, plans.toJson(), at);
  Future<Cached<MyPlans>?> myPlans() => _load(_plansKey, MyPlans.fromJson);

  /// Sign-out: the plans belong to that person.
  Future<void> clearMyPlans() => _prefs.remove(_plansKey);

  Future<void> _save(String key, Map<String, dynamic> json, DateTime at) =>
      _prefs.setString(key, jsonEncode({'at': at.toUtc().toIso8601String(), 'value': json}));

  Future<Cached<T>?> _load<T>(String key, T Function(Map<String, dynamic>) parse) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return Cached(parse(j['value'] as Map<String, dynamic>), DateTime.parse(j['at'] as String));
    } catch (_) {
      // A cache from an older app version that no longer parses is simply dropped.
      await _prefs.remove(key);
      return null;
    }
  }
}
