// App-wide services. main.dart overrides them with the loaded instances; tests override with fakes.
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'api.dart';
import 'cache.dart';
import 'identity.dart';
import 'realtime.dart';

final identityProvider = Provider<Identity>((ref) => throw UnimplementedError('overridden in main'));
final apiProvider = Provider<Api>((ref) => throw UnimplementedError('overridden in main'));
final cacheProvider = Provider<OfflineCache>((ref) => throw UnimplementedError('overridden in main'));
final realtimeProvider = Provider<RealtimeClient>((ref) => throw UnimplementedError('overridden in main'));

/// `ios` or `android`: the open beacon, claims and the socket report it.
final platformProvider = Provider<String>((ref) => Platform.isIOS ? 'ios' : 'android');

/// The clock, so tests can fix "Last updated …" and the start-time checks.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Native maps only when the build has a key for this platform (S7 §4.9, FR-018):
/// `--dart-define=MAPS=1`, set together with the key files.
final mapsEnabledProvider = Provider<bool>((ref) => const bool.fromEnvironment('MAPS'));

/// Bumped on sign-in and sign-out so screens that depend on who's signed in reload.
final sessionVersionProvider = StateProvider<int>((ref) => 0);
