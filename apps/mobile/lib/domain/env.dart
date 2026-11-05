// Build-time settings from `--dart-define` (S7 §4.10, S7b §4.4, §4.9).

/// `--dart-define=API_BASE_URL=…`; production by default (S7 §4.10).
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://depimls1pcvv4.cloudfront.net');

/// Native maps only when the build has a key for this platform (S7 §4.9, FR-018):
/// `--dart-define=MAPS=1`, set together with the key files.
const mapsEnabled = bool.fromEnvironment('MAPS');
