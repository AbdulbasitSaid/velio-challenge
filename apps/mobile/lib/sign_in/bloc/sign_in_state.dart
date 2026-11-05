part of 'sign_in_bloc.dart';

final class SignInState extends Equatable {
  const SignInState({this.busy = false, this.nameError, this.contactError, this.error, this.destination});

  final bool busy;
  final String? nameError;
  final String? contactError;

  /// The banner.
  final String? error;

  /// Signed in: where to go.
  final String? destination;

  @override
  List<Object?> get props => [busy, nameError, contactError, error, destination];
}
