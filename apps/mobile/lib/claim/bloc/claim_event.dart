part of 'claim_bloc.dart';

sealed class ClaimEvent extends Equatable {
  const ClaimEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opened: show what's being claimed.
final class ClaimRequested extends ClaimEvent {
  const ClaimRequested();
}

/// Confirm my spot, or Try again. [name] and [contact] are ignored when claiming as the saved person.
final class ClaimSubmitted extends ClaimEvent {
  const ClaimSubmitted({this.name = '', this.contact = ''});
  final String name;
  final String contact;

  @override
  List<Object?> get props => [name, contact];
}

final class ClaimNotYouPressed extends ClaimEvent {
  const ClaimNotYouPressed();
}
