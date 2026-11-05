// Idempotency keys (S7 claim, S7b FR-005): one per attempt, kept on the device until the attempt
// succeeds or fails for good, so a retry never books twice (V-CLM-1).
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AttemptKeys {
  AttemptKeys(this._prefs);
  final SharedPreferencesAsync _prefs;

  Future<String> forCode(String code) => _get('velio.claim_key.$code');

  Future<void> clear(String code) => _prefs.remove('velio.claim_key.$code');

  /// B1's attempt key for an activity (S7b FR-005).
  Future<String> forBooking(String activityId) => _get('velio.book_key.$activityId');

  Future<void> clearBooking(String activityId) => _prefs.remove('velio.book_key.$activityId');

  Future<String> _get(String k) async {
    final existing = await _prefs.getString(k);
    if (existing != null) return existing;
    final key = const Uuid().v4();
    await _prefs.setString(k, key);
    return key;
  }
}
