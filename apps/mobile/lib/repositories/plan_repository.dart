// Plans (S7 FR-011–FR-016): a Plan with its activity, My plans saved for offline, invites from a
// Plan, and public profiles.
import 'package:velio_api/velio_api.dart';

import '../data/api.dart';
import '../data/cache.dart';

export '../data/cache.dart' show Cached;

class PlanRepository {
  PlanRepository({required this._api, required this._cache, this._clock = DateTime.now});

  final Api _api;
  final OfflineCache _cache;
  final DateTime Function() _clock;

  Future<PlanView> plan(String id) => _api.plan(id);

  /// The Plan view carries no location, so the activity snapshot comes with it.
  Future<PublicActivity> activity(String id) => _api.activity(id);

  /// My plans from the API, saved for offline after each successful fetch.
  Future<MyPlans> myPlans() async {
    final plans = await _api.myPlans();
    await _cache.saveMyPlans(plans, _clock());
    return plans;
  }

  Future<Cached<MyPlans>?> cachedMyPlans() => _cache.myPlans();

  /// A vouch (`inviteeName`, `inviteeContact`, `note`) or the Plan's public link (`kind: public`).
  Future<Invite> createInvite(String planId, Map<String, Object?> body) => _api.createInvite(planId, body);

  Future<void> resumeInvite(String code) => _api.resumeInvite(code);

  Future<Profile> profile(String userId) => _api.profile(userId);
}
