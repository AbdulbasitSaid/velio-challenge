part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

final class SessionSubscriptionRequested extends SessionEvent {
  const SessionSubscriptionRequested();
}
