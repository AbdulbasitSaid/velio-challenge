part of 'invite_sheet_bloc.dart';

sealed class InviteSheetEvent extends Equatable {
  const InviteSheetEvent();

  @override
  List<Object?> get props => [];
}

final class InviteSheetVouchChosen extends InviteSheetEvent {
  const InviteSheetVouchChosen();
}

/// Create and share.
final class InviteSheetVouchSubmitted extends InviteSheetEvent {
  const InviteSheetVouchSubmitted({required this.name, this.contact = '', this.note = ''});
  final String name;
  final String contact;
  final String note;

  @override
  List<Object?> get props => [name, contact, note];
}

/// Share a link.
final class InviteSheetLinkRequested extends InviteSheetEvent {
  const InviteSheetLinkRequested();
}

final class InviteSheetResumePressed extends InviteSheetEvent {
  const InviteSheetResumePressed();
}
