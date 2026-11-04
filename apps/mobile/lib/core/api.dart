// API access (S7 §4.3, §4.4): the generated client over one Dio with our interceptors. Every request
// carries X-Device-Id, X-Client: mobile, a W3C traceparent and, when signed in, the bearer token
// (FR-003). A 401 clears the session. Nothing is logged (NFR-006).
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:velio_api/velio_api.dart';

import 'identity.dart';

/// `--dart-define=API_BASE_URL=…`; production by default (S7 §4.10).
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://depimls1pcvv4.cloudfront.net');

/// The API's typed error, or a network failure (`code == null`, `status == null`).
class ApiException implements Exception {
  const ApiException({this.status, this.code, this.message = ''});
  final int? status;
  final String? code;
  final String message;

  bool get network => status == null;

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final res = error.response;
      if (res == null) return const ApiException(message: 'network');
      final body = res.data;
      final e = body is Map ? body['error'] : null;
      if (e is Map && e['code'] is String) {
        return ApiException(status: res.statusCode, code: e['code'] as String, message: '${e['message']}');
      }
      return ApiException(status: res.statusCode, code: 'internal');
    }
    return ApiException(code: 'internal', message: '$error');
  }

  @override
  String toString() => 'ApiException($status, $code)';
}

final _random = Random.secure();
String _hex(int bytes) => List.generate(bytes, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

/// A new sampled W3C trace context per request (MVP plan §4.12).
String newTraceparent() => '00-${_hex(16)}-${_hex(8)}-01';

class VelioInterceptor extends Interceptor {
  VelioInterceptor(this.identity, {this.onUnauthorized});
  final Identity identity;
  final void Function()? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['x-device-id'] = identity.deviceId;
    options.headers['x-client'] = 'mobile';
    options.headers['traceparent'] = newTraceparent();
    final token = identity.token;
    if (token != null) options.headers['authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A request that carried a token and got 401: the session ended (expired, or signed out elsewhere).
    if (err.response?.statusCode == 401 && err.requestOptions.headers['authorization'] != null) {
      identity.signOut().then((_) => onUnauthorized?.call());
    }
    handler.next(err);
  }
}

Dio createDio(Identity identity, {void Function()? onUnauthorized, String baseUrl = apiBaseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );
  dio.interceptors.add(VelioInterceptor(identity, onUnauthorized: onUnauthorized));
  return dio;
}

/// The calls the app makes, each mapping failures to [ApiException].
class Api {
  Api(this.dio, this.identity) : _api = VelioApi(dio: dio, interceptors: const []).getDefaultApi();
  final Dio dio;
  final Identity identity;
  final DefaultApi _api;

  Future<T> _call<T>(Future<Response<T>> Function() request) async {
    try {
      final res = await request();
      return res.data as T;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<InviteView> invite(String code) => _call(() => _api.apiInvitesCodeGet(code: code));

  /// PRD Scope challenge 2: sent once, after the invite's first frame (FR-009). Failures are ignored.
  Future<void> open(String code, String platform) async {
    try {
      await dio.post<void>('/api/invites/$code/opens', data: {'platform': platform});
    } catch (_) {}
  }

  Future<ClaimResponse> claim(
    String code, {
    required String idempotencyKey,
    required String platform,
    String? displayName,
    String? contact,
  }) => _call(
    () => _api.apiInvitesCodeClaimsPost(
      code: code,
      idempotencyKey: idempotencyKey,
      claimCreate: ClaimCreate(
        displayName: displayName,
        contact: contact,
        platform: platform == 'ios' ? ClaimCreatePlatformEnum.ios : ClaimCreatePlatformEnum.android,
      ),
    ),
  );

  Future<PublicActivity> activity(String id) => _call(() => _api.apiActivitiesIdGet(id: id));

  Future<NextSteps> nextSteps(String activityId) => _call(() => _api.apiActivitiesIdNextStepsGet(id: activityId));

  Future<PlanView> plan(String id) => _call(() => _api.apiPlansIdGet(id: id));

  Future<MyPlans> myPlans() => _call(() => _api.apiMePlansGet());

  Future<Profile> profile(String userId) => _call(() => _api.apiUsersIdProfileGet(id: userId));

  Future<SessionResponse> signIn(String displayName, String contact) => _call(
    () => _api.apiSessionsPost(
      sessionCreate: SessionCreate(displayName: displayName, contact: contact),
    ),
  );

  Future<void> signOut() async {
    try {
      await _api.apiSessionsCurrentDelete();
    } catch (_) {
      // Signing out locally is what matters; the server session expires on its own.
    }
  }

  /// Hand-built body: the generator merges InviteCreate's oneOf into one class with a required
  /// `inviteeName`, which can't express a public link (S7 §4.3 fallback, PLANNING change log).
  Future<Invite> createInvite(String planId, Map<String, Object?> body) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/api/plans/$planId/invites',
        data: {...body}..removeWhere((_, v) => v == null),
      );
      return Invite.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> resumeInvite(String code) => _call(() => _api.apiInvitesCodePauseDelete(code: code));
}
