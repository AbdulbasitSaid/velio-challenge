part of 'invite_sheet_bloc.dart';

enum InviteSheetStep { choose, vouch, link }

final class InviteSheetState extends Equatable {
  const InviteSheetState({
    this.step = InviteSheetStep.choose,
    this.busy = false,
    this.nameError,
    this.contactError,
    this.error,
    this.link,
    this.message,
  });

  final InviteSheetStep step;
  final bool busy;
  final String? nameError;
  final String? contactError;

  /// The banner.
  final String? error;

  /// The Plan's public link.
  final Invite? link;

  /// A vouch was created: the message for the share sheet.
  final String? message;

  InviteSheetState copyWith({
    InviteSheetStep? step,
    bool? busy,
    String? Function()? nameError,
    String? Function()? contactError,
    String? Function()? error,
    Invite? Function()? link,
    String? Function()? message,
  }) => InviteSheetState(
    step: step ?? this.step,
    busy: busy ?? this.busy,
    nameError: nameError != null ? nameError() : this.nameError,
    contactError: contactError != null ? contactError() : this.contactError,
    error: error != null ? error() : this.error,
    link: link != null ? link() : this.link,
    message: message != null ? message() : this.message,
  );

  @override
  List<Object?> get props => [step, busy, nameError, contactError, error, link, message];
}
