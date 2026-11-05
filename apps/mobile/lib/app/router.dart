// Routes (S7 §4.5, S7b §4.1) and deep links (S7 §4.6). Booker roots share a bottom bar (Explore, Code,
// My plans); detail and host routes sit above it. app_links delivers the cold-start link and later
// ones; only `https://<host>/i/<code>` with a valid code opens in the app (SEC-005). Any other path
// shows "This link needs a newer version of the app" with the browser as the fallback.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../activity/activity.dart';
import '../activity_form/activity_form.dart';
import '../attendance/attendance.dart';
import '../claim/claim.dart';
import '../code_entry/code_entry.dart';
import '../domain/env.dart';
import '../domain/format.dart';
import '../explore/explore.dart';
import '../host_list/host_list.dart';
import '../invite/invite.dart';
import '../my_plans/my_plans.dart';
import '../plan/plan.dart';
import '../profile/profile.dart';
import '../shell/shell.dart';
import '../sign_in/sign_in.dart';
import '../ui/error_screen.dart';

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

String? _uuidOr(String id, String fallback) => _uuid.hasMatch(id) ? null : fallback;

/// [initialLocation] is `/host` when the saved role is host (S7b FR-001).
GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => BookerShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/explore', builder: (_, _) => const ExplorePage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, s) => CodeEntryPage(key: ValueKey(s.uri), initialError: s.uri.queryParameters['error']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/me/plans', builder: (_, _) => const MyPlansPage())],
        ),
      ],
    ),
    GoRoute(
      path: '/communities/:slug',
      builder: (_, s) => ExplorePage(key: ValueKey(s.pathParameters['slug']), slug: s.pathParameters['slug']),
    ),
    GoRoute(
      path: '/activities/:id',
      redirect: (_, s) => _uuidOr(s.pathParameters['id']!, '/explore'),
      builder: (_, s) => ActivityPage(key: ValueKey(s.pathParameters['id']), id: s.pathParameters['id']!),
    ),
    GoRoute(path: '/host', builder: (_, _) => const HostListPage()),
    GoRoute(path: '/host/new', builder: (_, _) => const ActivityFormPage()),
    GoRoute(
      path: '/host/:id/edit',
      redirect: (_, s) => _uuidOr(s.pathParameters['id']!, '/host'),
      builder: (_, s) => ActivityFormPage(
        key: ValueKey(s.uri),
        id: s.pathParameters['id'],
        published: s.uri.queryParameters['published'] == '1',
      ),
    ),
    GoRoute(
      path: '/host/:id/attendance',
      redirect: (_, s) => _uuidOr(s.pathParameters['id']!, '/host'),
      builder: (_, s) => AttendancePage(key: ValueKey(s.pathParameters['id']), id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/i/:code',
      redirect: (_, s) {
        final code = normaliseCode(s.pathParameters['code'] ?? '');
        if (code == null) return '/?error=invalid';
        return code == s.pathParameters['code'] ? null : s.uri.path.replaceFirst(s.pathParameters['code']!, code);
      },
      builder: (_, s) => InvitePage(key: ValueKey(s.pathParameters['code']), code: s.pathParameters['code']!),
      routes: [
        GoRoute(
          path: 'claim',
          builder: (_, s) => ClaimPage(code: s.pathParameters['code']!),
        ),
        GoRoute(
          path: 'in/:planId',
          redirect: (_, s) => _uuid.hasMatch(s.pathParameters['planId']!) ? null : '/',
          builder: (_, s) => YoureInPage(planId: s.pathParameters['planId']!),
        ),
      ],
    ),
    GoRoute(
      path: '/plans/:id',
      redirect: (_, s) => _uuidOr(s.pathParameters['id']!, '/me/plans'),
      builder: (_, s) => PlanPage(key: ValueKey(s.pathParameters['id']), planId: s.pathParameters['id']!),
      routes: [
        // B2 after a direct booking: the same "You're in" as after a claim (S7b PLANNING §12 D4).
        GoRoute(
          path: 'welcome',
          builder: (_, s) => YoureInPage(planId: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/users/:id',
      redirect: (_, s) => _uuid.hasMatch(s.pathParameters['id']!) ? null : '/',
      builder: (_, s) => ProfilePage(userId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/signin',
      builder: (_, s) => SignInPage(next: s.uri.queryParameters['next']),
    ),
    GoRoute(
      path: '/update',
      builder: (_, s) => ErrorScreen(kind: ErrorKind.newerApp, browserUrl: s.uri.queryParameters['url']),
    ),
  ],
  errorBuilder: (_, _) => const ErrorScreen(kind: ErrorKind.notFound),
);
