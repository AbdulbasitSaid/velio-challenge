// How a screen's failed load is shown (S7 FR-017 error screens).
import 'api_exception.dart';

enum LoadError {
  notFound,
  offline,
  server,

  /// The session ended: sign in again.
  signIn;

  /// [notFound] covers the statuses that mean "not here for you" on this screen.
  static LoadError of(ApiException e, {Set<int> notFound = const {404}}) {
    if (e.status != null && notFound.contains(e.status)) return LoadError.notFound;
    return e.network ? LoadError.offline : LoadError.server;
  }
}
