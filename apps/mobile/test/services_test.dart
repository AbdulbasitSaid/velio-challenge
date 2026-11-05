// V-ID-1 (headers, 401, secure storage), V-CACHE-1 (offline cache), V-CLM-1 (unit: one key per attempt).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:velio/data/api.dart';
import 'package:velio/data/attempt_keys.dart';
import 'package:velio/data/cache.dart';
import 'package:velio/data/identity.dart';
import 'package:velio_api/velio_api.dart';

import 'fixtures.dart';

/// Answers every request with [status] and records what was sent.
class _Recorder extends Interceptor {
  _Recorder(this.status);
  final int status;
  final requests = <RequestOptions>[];
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    if (status >= 400) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: status,
            data: {
              'error': {'code': status == 401 ? 'unauthenticated' : 'sold_out', 'message': 'x', 'requestId': 'r'},
            },
          ),
        ),
        true,
      );
    } else {
      handler.resolve(Response(requestOptions: options, statusCode: status, data: null));
    }
  }
}

void main() {
  late MemorySecretStore secrets;
  late SharedPreferencesAsync prefs;
  late Identity identity;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
    secrets = MemorySecretStore();
    identity = Identity(secrets, prefs);
    await identity.load();
  });

  group('identity and requests (V-ID-1)', () {
    test('a device ID is created once and kept in secure storage', () async {
      final id = identity.deviceId;
      expect(id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      final again = Identity(secrets, prefs);
      await again.load();
      expect(again.deviceId, id);
      expect(await prefs.getKeys(), isNot(contains('velio.device_id')), reason: 'never in shared_preferences');
    });

    test('a token left in the keychain from before a reinstall is dropped', () async {
      await identity.signIn('tok', const LocalProfile(userId: 'u', displayName: 'Z', maskedContact: '•••'));
      // Reinstall: preferences are wiped, the keychain isn't.
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final fresh = Identity(secrets, SharedPreferencesAsync());
      await fresh.load();
      expect(fresh.signedIn, isFalse);
      expect(await secrets.read('velio.token'), isNull);
      expect(fresh.deviceId, identity.deviceId, reason: 'the device ID survives');
      // A normal relaunch keeps the session.
      await fresh.signIn('tok2', const LocalProfile(userId: 'u', displayName: 'Z', maskedContact: '•••'));
      final again = Identity(secrets, SharedPreferencesAsync());
      await again.load();
      expect(again.token, 'tok2');
    });

    test('every request carries the device ID, X-Client and a traceparent; bearer only when signed in', () async {
      final rec = _Recorder(204);
      final dio = createDio(identity, baseUrl: 'https://x.test')..interceptors.add(rec);
      await dio.get<void>('/api/healthz');
      var h = rec.requests.last.headers;
      expect(h['x-device-id'], identity.deviceId);
      expect(h['x-client'], 'mobile');
      expect(h['traceparent'], matches(RegExp(r'^00-[0-9a-f]{32}-[0-9a-f]{16}-01$')));
      expect(h.containsKey('authorization'), isFalse);

      await identity.signIn(
        'tok',
        const LocalProfile(userId: 'u', displayName: 'Zainab Okafor', maskedContact: 'z••••@gmail.com'),
      );
      await dio.get<void>('/api/me');
      h = rec.requests.last.headers;
      expect(h['authorization'], 'Bearer tok');
      expect(await secrets.read('velio.token'), 'tok');
      expect(await prefs.getKeys(), isNot(contains('velio.token')));
    });

    test('a 401 on a signed-in request clears the session and the local profile', () async {
      await identity.signIn('tok', const LocalProfile(userId: 'u', displayName: 'Z', maskedContact: '•••'));
      var cleared = false;
      final dio = createDio(identity, baseUrl: 'https://x.test', onUnauthorized: () => cleared = true)
        ..interceptors.add(_Recorder(401));
      await expectLater(dio.get<void>('/api/me'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);
      expect(identity.signedIn, isFalse);
      expect(identity.profile, isNull);
      expect(await secrets.read('velio.token'), isNull);
      expect(cleared, isTrue);
    });

    test('errors map to the API code; no response is a network failure', () {
      final opts = RequestOptions(path: '/x');
      final api = apiException(
        DioException(
          requestOptions: opts,
          response: Response(
            requestOptions: opts,
            statusCode: 409,
            data: {
              'error': {'code': 'sold_out', 'message': 'm', 'requestId': 'r'},
            },
          ),
        ),
      );
      expect((api.status, api.code, api.network), (409, 'sold_out', false));
      final net = apiException(DioException(requestOptions: opts, type: DioExceptionType.connectionError));
      expect(net.network, isTrue);
    });
  });

  group('offline cache (V-CACHE-1)', () {
    test('the last invite and My plans come back with their fetch time', () async {
      final cache = OfflineCache(prefs);
      final at = DateTime.utc(2026, 11, 4, 12);
      await cache.saveInvite(inviteView(), at);
      final c = await cache.invite('K7PQ2N');
      expect(c!.value.activity.location.venueName, 'Lake Naivasha Boat Club');
      expect(c.fetchedAt, at);
      expect(await cache.invite('OTHER1'), isNull, reason: 'only the code asked for');

      await cache.saveMyPlans(MyPlans(upcoming: const [], past: const []), at);
      expect((await cache.myPlans())!.fetchedAt, at);
      await cache.clearMyPlans();
      expect(await cache.myPlans(), isNull);
    });

    test('an unreadable cache is dropped, not fatal', () async {
      await prefs.setString('velio.cache.invite', '{"at":"x","value":{}}');
      expect(await OfflineCache(prefs).invite('K7PQ2N'), isNull);
      expect(await prefs.getString('velio.cache.invite'), isNull);
    });
  });

  group('claim attempts (V-CLM-1, unit)', () {
    test('one key per code, reused until cleared', () async {
      final keys = AttemptKeys(prefs);
      final first = await keys.forCode('K7PQ2N');
      expect(await keys.forCode('K7PQ2N'), first, reason: 'a retry reuses the key');
      expect(await keys.forCode('H4XM9R'), isNot(first));
      await keys.clear('K7PQ2N');
      expect(await keys.forCode('K7PQ2N'), isNot(first));
    });
  });
}
