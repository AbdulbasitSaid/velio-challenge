// Browsing and booking (S7b FR-003–FR-005): communities, activity snapshots and direct booking with
// one idempotency key per attempt.
import 'package:velio_api/velio_api.dart';

import '../data/api.dart';
import '../data/attempt_keys.dart';

class ActivityRepository {
  ActivityRepository({required this._api, required this._keys});

  final Api _api;
  final AttemptKeys _keys;

  Future<CommunityList> communities() => _api.communities();

  Future<CommunityPage> community(String slug) => _api.community(slug);

  Future<PublicActivity> activity(String id) => _api.activity(id);

  Future<NextSteps> nextSteps(String activityId) => _api.nextSteps(activityId);

  /// B1: the attempt's key is reused until [clearAttempt] (S7b FR-005).
  Future<BookingResponse> book(String activityId) async =>
      _api.book(activityId, idempotencyKey: await _keys.forBooking(activityId));

  Future<void> clearAttempt(String activityId) => _keys.clearBooking(activityId);
}
