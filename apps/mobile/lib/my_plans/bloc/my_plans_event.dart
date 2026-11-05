part of 'my_plans_bloc.dart';

sealed class MyPlansEvent extends Equatable {
  const MyPlansEvent();

  @override
  List<Object?> get props => [];
}

/// Follow sign-in and sign-out for as long as the screen is open.
final class MyPlansSubscriptionRequested extends MyPlansEvent {
  const MyPlansSubscriptionRequested();
}

/// The screen opened, pull to refresh, Try again, or someone signed in or out ([reset]).
final class MyPlansRequested extends MyPlansEvent {
  const MyPlansRequested({this.reset = false});
  final bool reset;

  @override
  List<Object?> get props => [reset];
}

final class MyPlansTabChanged extends MyPlansEvent {
  const MyPlansTabChanged({required this.past});
  final bool past;

  @override
  List<Object?> get props => [past];
}
