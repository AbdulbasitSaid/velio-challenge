// Routes (S7 §4.5) and deep links (§4.6). app_links delivers the cold-start link and later ones;
// only `https://<host>/i/<code>` with a valid code opens in the app (SEC-005). Any other path shows
// "This link needs a newer version of the app" with the browser as the fallback.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../features/claim.dart';
import '../features/code_entry.dart';
import '../features/errors.dart';
import '../features/invite.dart';
import '../features/my_plans.dart';
import '../features/plan.dart';
import '../features/profile.dart';
import '../features/signin.dart';

final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// The app route for an incoming link, or null when the link isn't ours at all.
String? routeForLink(Uri link, {String apiBase = apiBaseUrl}) {
  final host = Uri.parse(apiBase).host;
  if (link.host != host) return null;
  final segments = link.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length >= 2 && segments.first == 'i') {
    final code = normaliseCode(Uri.decodeComponent(segments[1]));
    return code == null ? '/?error=invalid' : '/i/$code';
  }
  return '/update?url=${Uri.encodeComponent(link.toString())}';
}

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, s) => CodeEntryScreen(key: ValueKey(s.uri), initialError: s.uri.queryParameters['error']),
    ),
    GoRoute(
      path: '/i/:code',
      redirect: (_, s) {
        final code = normaliseCode(s.pathParameters['code'] ?? '');
        if (code == null) return '/?error=invalid';
        return code == s.pathParameters['code'] ? null : s.uri.path.replaceFirst(s.pathParameters['code']!, code);
      },
      builder: (_, s) => InviteScreenPage(key: ValueKey(s.pathParameters['code']), code: s.pathParameters['code']!),
      routes: [
        GoRoute(
          path: 'claim',
          builder: (_, s) => ClaimScreen(code: s.pathParameters['code']!),
        ),
        GoRoute(
          path: 'in/:planId',
          redirect: (_, s) => _uuid.hasMatch(s.pathParameters['planId']!) ? null : '/',
          builder: (_, s) => YoureInScreen(planId: s.pathParameters['planId']!),
        ),
      ],
    ),
    GoRoute(
      path: '/plans/:id',
      redirect: (_, s) => _uuid.hasMatch(s.pathParameters['id']!) ? null : '/me/plans',
      builder: (_, s) => PlanScreen(key: ValueKey(s.pathParameters['id']), planId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/me/plans', builder: (_, _) => const MyPlansScreen()),
    GoRoute(
      path: '/users/:id',
      redirect: (_, s) => _uuid.hasMatch(s.pathParameters['id']!) ? null : '/',
      builder: (_, s) => ProfileScreen(userId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/signin',
      builder: (_, s) => SignInScreen(next: s.uri.queryParameters['next']),
    ),
    GoRoute(
      path: '/update',
      builder: (_, s) => ErrorScreen(kind: ErrorKind.newerApp, browserUrl: s.uri.queryParameters['url']),
    ),
  ],
  errorBuilder: (_, _) => const ErrorScreen(kind: ErrorKind.notFound),
);
