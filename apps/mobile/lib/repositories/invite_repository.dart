// Invites (S7 FR-004–FR-012): look up a code, the open beacon, claims with one idempotency key per
// attempt, and the last invite saved for offline (PRD M2). Nothing is ever queued.
import 'package:velio_api/velio_api.dart';

import '../data/api.dart';
import '../data/attempt_keys.dart';
import '../data/cache.dart';

export '../data/cache.dart' show Cached;

class InviteRepository {
  InviteRepository({
    required this._api,
    required this._cache,
    required this._keys,
    required this._platform,
    this._clock = DateTime.now,
  });

  final Api _api;
  final OfflineCache _cache;
  final AttemptKeys _keys;
  final String _platform;
  final DateTime Function() _clock;

  /// The invite from the API, saved for offline after each successful fetch.
  Future<InviteView> invite(String code) async {
    final view = await _api.invite(code);
    await _cache.saveInvite(view, _clock());
    return view;
  }

  /// The saved copy, if it is this code's.
  Future<Cached<InviteView>?> cachedInvite(String code) => _cache.invite(code);

  /// PRD Scope challenge 2: the open beacon. Failures are ignored.
  Future<void> open(String code) => _api.open(code, _platform);

  /// The attempt's key is reused until [clearAttempt] (V-CLM-1).
  Future<ClaimResponse> claim(String code, {String? displayName, String? contact}) async => _api.claim(
    code,
    idempotencyKey: await _keys.forCode(code),
    platform: _platform,
    displayName: displayName,
    contact: contact,
  );

  Future<void> clearAttempt(String code) => _keys.clear(code);

  Future<NextSteps> nextSteps(String activityId) => _api.nextSteps(activityId);
}
