part of 'host_list_bloc.dart';

final class HostListState extends Equatable {
  const HostListState({required this.signedIn, this.data, this.error, this.past = false});

  final bool signedIn;

  /// Null until the first load.
  final HostActivityList? data;
  final LoadError? error;
  final bool past;

  /// Signed out, or the session ended: ask to sign in.
  bool get needsSignIn => !signedIn || error == LoadError.signIn;

  /// The list to show, or null while loading.
  List<HostActivityItem>? get items => data == null ? null : (past ? data!.past : data!.upcoming);

  bool get empty => data != null && data!.upcoming.isEmpty && data!.past.isEmpty;

  HostListState copyWith({
    bool? signedIn,
    HostActivityList? Function()? data,
    LoadError? Function()? error,
    bool? past,
  }) => HostListState(
    signedIn: signedIn ?? this.signedIn,
    data: data != null ? data() : this.data,
    error: error != null ? error() : this.error,
    past: past ?? this.past,
  );

  @override
  List<Object?> get props => [signedIn, data, error, past];
}
