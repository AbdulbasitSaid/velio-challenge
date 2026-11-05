// Who is signed in (S7 §4.4, FR-017): the session token and the local profile, and a stream of
// changes so screens that depend on who's signed in reload, and the socket reconnects.
import 'dart:async';

import '../data/api.dart';
import '../data/cache.dart';
import '../data/identity.dart';
import '../domain/format.dart';

export '../data/identity.dart' show LocalProfile;

class SessionRepository {
  SessionRepository({required this._identity, required this._api, required this._cache});

  final Identity _identity;
  final Api _api;
  final OfflineCache _cache;
  final _changes = StreamController<LocalProfile?>.broadcast();

  LocalProfile? get profile => _identity.profile;
  bool get signedIn => _identity.signedIn;

  /// Each sign-in, sign-out and ended session, with the new profile (null when signed out).
  Stream<LocalProfile?> get changes => _changes.stream;

  /// X1: name and the phone or email used before. Only a masked contact is kept (SEC-002).
  Future<void> signIn(String displayName, String contact) async {
    final res = await _api.signIn(displayName, contact);
    await adopt(res.token!, userId: res.user.id, displayName: res.user.displayName, contact: contact);
  }

  /// A session the API issued with another response, such as a first claim.
  Future<void> adopt(
    String token, {
    required String userId,
    required String displayName,
    required String contact,
  }) async {
    await _identity.signIn(
      token,
      LocalProfile(userId: userId, displayName: displayName, maskedContact: maskContact(contact)),
    );
    _changes.add(profile);
  }

  /// "Not you?": end the session here; the plans on the device belong to that person.
  Future<void> signOut() async {
    await _api.signOut();
    await _identity.signOut();
    await _cache.clearMyPlans();
    _changes.add(null);
  }

  /// A request with a token got 401; the interceptor has already forgotten the session.
  void ended() => _changes.add(null);
}
