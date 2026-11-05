// Velio for iOS and Android (S7). Loads identity, builds the data providers and repositories, then
// starts the app with them.
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'app/config.dart';
import 'app/router.dart';
import 'app/view/app.dart';
import 'app/view/app_scope.dart';
import 'data/api.dart';
import 'data/attempt_keys.dart';
import 'data/cache.dart';
import 'data/identity.dart';
import 'data/photo.dart';
import 'data/places.dart';
import 'data/realtime.dart';
import 'domain/env.dart';
import 'domain/role.dart';
import 'repositories/activity_repository.dart';
import 'repositories/connectivity_repository.dart';
import 'repositories/host_repository.dart';
import 'repositories/invite_repository.dart';
import 'repositories/live_repository.dart';
import 'repositories/plan_repository.dart';
import 'repositories/preferences_repository.dart';
import 'repositories/session_repository.dart';

Future<void> main() => run();

/// The gallery, downscaled natively first so the isolate decodes a small file (S7b §4.5). Null when
/// the host cancels.
Future<Uint8List?> pickFromGallery() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2560,
    maxHeight: 2560,
    imageQuality: 92,
  );
  return file?.readAsBytes();
}

/// [photoPicker] lets integration tests replace the gallery (S7b V-MAN-1).
Future<void> run({Future<Uint8List?> Function()? photoPicker}) async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await initializeDateFormatting('en_GB');
  final config = AppConfig(platform: Platform.isIOS ? 'ios' : 'android', mapsEnabled: mapsEnabled);
  final prefs = SharedPreferencesAsync();
  final identity = Identity(const PlatformSecretStore(), prefs);
  await identity.load();
  final preferences = PreferencesRepository(prefs);
  final role = await preferences.loadRole();

  late final SessionRepository session;
  final api = Api(createDio(identity, onUnauthorized: () => session.ended()), identity);
  final cache = OfflineCache(prefs);
  final keys = AttemptKeys(prefs);
  session = SessionRepository(identity: identity, api: api, cache: cache);
  final live = LiveRepository(
    RealtimeClient(url: realtimeUrl(apiBaseUrl), platform: config.platform, token: () => identity.token),
  );
  // The socket's identity is fixed at connect, so it follows each sign-in and sign-out.
  session.changes.listen((_) => live.reconnect());

  runApp(
    AppScope(
      config: config,
      sessionRepository: session,
      preferencesRepository: preferences,
      connectivityRepository: ConnectivityRepository(),
      liveRepository: live,
      inviteRepository: InviteRepository(api: api, cache: cache, keys: keys, platform: config.platform),
      activityRepository: ActivityRepository(api: api, keys: keys),
      planRepository: PlanRepository(api: api, cache: cache),
      hostRepository: HostRepository(
        api: api,
        photos: PhotoUploader(api),
        places: PlacesClient(platform: config.platform),
        pickPhoto: photoPicker ?? pickFromGallery,
      ),
      role: role,
      child: VelioApp(router: createRouter(initialLocation: role == Role.host ? '/host' : '/')),
    ),
  );
}
