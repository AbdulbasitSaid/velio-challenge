// SessionRepository (V-REPO-1, FR-011): sign-in keeps only a masked contact, and every sign-in,
// sign-out and ended session is announced so screens reload and the socket reconnects.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:velio/data/api.dart';
import 'package:velio/data/cache.dart';
import 'package:velio/data/identity.dart';
import 'package:velio/repositories/session_repository.dart';
import 'package:velio_api/velio_api.dart';

import '../fixtures.dart';

class SignInApi extends Api {
  SignInApi(Identity identity) : super(Dio(), identity);
  @override
  Future<SessionResponse> signIn(String displayName, String contact) async =>
      SessionResponse.fromJson({'token': 'tok', 'user': member('u1', 'Zainab O.', displayName)});
  @override
  Future<void> signOut() async {}
}

void main() {
  late Identity identity;
  late OfflineCache cache;
  late SessionRepository session;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    identity = Identity(MemorySecretStore(), prefs);
    await identity.load();
    cache = OfflineCache(prefs);
    session = SessionRepository(identity: identity, api: SignInApi(identity), cache: cache);
  });

  test('sign in, then sign out: profile, masked contact and changes', () async {
    final changes = <LocalProfile?>[];
    session.changes.listen(changes.add);
    await session.signIn('Zainab Okafor', '+254712345678');
    expect(session.signedIn, isTrue);
    expect(identity.token, 'tok');
    expect(session.profile!.maskedContact, isNot(contains('345678')));

    await cache.saveMyPlans(MyPlans.fromJson({'upcoming': const [], 'past': const []}), DateTime.utc(2026));
    await session.signOut();
    await pumpEventQueue();
    expect(session.signedIn, isFalse);
    expect(await cache.myPlans(), isNull);
    expect(changes.map((p) => p?.userId), ['u1', null]);
  });

  test('an ended session is announced', () async {
    final changes = <LocalProfile?>[];
    session.changes.listen(changes.add);
    session.ended();
    await pumpEventQueue();
    expect(changes, [null]);
  });
}
