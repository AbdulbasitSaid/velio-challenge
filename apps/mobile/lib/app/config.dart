// Values fixed for a run of the app, provided at the root so tests can pin them.

class AppConfig {
  const AppConfig({required this.platform, this.clock = DateTime.now, this.mapsEnabled = false});

  /// `ios` or `android`: the open beacon, claims and the socket report it.
  final String platform;

  /// The clock, so tests can fix "Last updated …" and the start-time checks.
  final DateTime Function() clock;

  /// Native maps (S7 §4.9, FR-018); see `mapsEnabled` in `domain/env.dart`.
  final bool mapsEnabled;
}
