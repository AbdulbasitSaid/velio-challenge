// The app's root view: theme, router, deep links and the app lifecycle.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../repositories/live_repository.dart';
import '../router.dart';
import '../theme.dart';

class VelioApp extends StatefulWidget {
  const VelioApp({super.key, required this.router, this.links});
  final GoRouter router;

  /// Deep links; null in tests.
  final Stream<Uri>? links;

  @override
  State<VelioApp> createState() => _VelioAppState();
}

class _VelioAppState extends State<VelioApp> with WidgetsBindingObserver {
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
    context.read<LiveRepository>().setForeground(state == AppLifecycleState.resumed);
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
