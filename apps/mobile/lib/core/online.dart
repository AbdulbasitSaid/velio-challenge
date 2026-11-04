// Connectivity as a hint only (S7 §4.8, Risks): screens treat a failed request as the truth and use
// this to react quickly when the phone drops or regains its connection.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);
  yield online(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(online);
});

/// True unless the platform says there's no network at all.
bool isOnline(WidgetRef ref) => ref.watch(onlineProvider).value ?? true;
