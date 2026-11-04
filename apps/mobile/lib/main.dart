// Velio for iOS and Android (S7). Loads identity, then starts the app with its services.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'app/router.dart';
import 'app/theme.dart';
import 'core/api.dart';
import 'core/cache.dart';
import 'core/identity.dart';
import 'core/photo.dart';
import 'core/providers.dart';
import 'core/realtime.dart';
import 'core/role.dart';

Future<void> main() => run();

/// [overrides] let integration tests swap a platform service, such as the photo picker (S7b V-MAN-1).
Future<void> run({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await initializeDateFormatting('en_GB');
  final prefs = SharedPreferencesAsync();
  final identity = Identity(const PlatformSecretStore(), prefs);
  await identity.load();
  final role = await loadRole(prefs);
  final router = createRouter(initialLocation: role == Role.host ? '/host' : '/');
  final container = ProviderContainer();
  final dio = createDio(identity, onUnauthorized: () => container.read(sessionVersionProvider.notifier).state++);
  final api = Api(dio, identity);
  final scoped = ProviderContainer(
    parent: container,
    overrides: [
      identityProvider.overrideWithValue(identity),
      prefsProvider.overrideWithValue(prefs),
      roleProvider.overrideWith((ref) => role),
      apiProvider.overrideWithValue(api),
      // Overridden here, not derived: a provider that isn't overridden resolves in the root
      // container, where the API isn't (S7b V-MAN-1 found this).
      photoUploaderProvider.overrideWithValue(PhotoUploader(api)),
      cacheProvider.overrideWithValue(OfflineCache(prefs)),
      realtimeProvider.overrideWith(
        (ref) => RealtimeClient(
          url: realtimeUrl(apiBaseUrl),
          platform: ref.read(platformProvider),
          token: () => identity.token,
        ),
      ),
      ...overrides,
    ],
  );
  container.listen(sessionVersionProvider, (_, _) => scoped.read(realtimeProvider).reconnect());
  runApp(
    UncontrolledProviderScope(
      container: scoped,
      child: VelioApp(router: router),
    ),
  );
}

class VelioApp extends ConsumerStatefulWidget {
  const VelioApp({super.key, required this.router, this.links});
  final GoRouter router;

  /// Deep links; null in tests.
  final Stream<Uri>? links;

  @override
  ConsumerState<VelioApp> createState() => _VelioAppState();
}

class _VelioAppState extends ConsumerState<VelioApp> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // uriLinkStream delivers the link the app was opened with, then later ones.
    _links = (widget.links ?? AppLinks().uriLinkStream).listen((uri) {
      final route = routeForLink(uri);
      if (route != null) widget.router.go(route);
    });
  }

  @override
  void dispose() {
    _links?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The socket closes in the background and resumes with a refetch (S7 FR-008).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(realtimeProvider).setForeground(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Velio',
    debugShowCheckedModeBanner: false,
    theme: velioTheme(),
    routerConfig: widget.router,
    // Phone layout everywhere, text scaling up to 200% (UI-D5).
    builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: 2, child: child!),
  );
}
