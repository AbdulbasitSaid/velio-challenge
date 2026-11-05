// Connectivity as a hint only (S7 §4.8, Risks): screens treat a failed request as the truth and use
// this to react quickly when the phone drops or regains its connection.
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityRepository {
  ConnectivityRepository({this._online});
  final Stream<bool>? _online;

  /// True unless the platform says there's no network at all; the current value first.
  Stream<bool> get online => _online ?? _platform();

  static Stream<bool> _platform() async* {
    final c = Connectivity();
    bool online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);
    yield online(await c.checkConnectivity());
    yield* c.onConnectivityChanged.map(online);
  }
}
