part of 'code_entry_bloc.dart';

sealed class CodeEntryEvent extends Equatable {
  const CodeEntryEvent();

  @override
  List<Object?> get props => [];
}

final class CodeEntryChanged extends CodeEntryEvent {
  const CodeEntryChanged(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

/// Open invite, or Go on the keyboard.
final class CodeEntrySubmitted extends CodeEntryEvent {
  const CodeEntrySubmitted();
}
