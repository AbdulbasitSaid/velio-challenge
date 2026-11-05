part of 'session_bloc.dart';

final class SessionState extends Equatable {
  const SessionState(this.profile);

  /// Null when signed out.
  final LocalProfile? profile;

  bool get signedIn => profile != null;

  @override
  List<Object?> get props => [profile?.userId, profile?.displayName, profile?.maskedContact];
}
