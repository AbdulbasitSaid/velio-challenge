part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

final class SignInSubmitted extends SignInEvent {
  const SignInSubmitted({required this.name, required this.contact});
  final String name;
  final String contact;

  @override
  List<Object?> get props => [name, contact];
}
