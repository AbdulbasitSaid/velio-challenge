part of 'code_entry_bloc.dart';

enum CodeEntryError { invalid, limited }

final class CodeEntryState extends Equatable {
  const CodeEntryState({this.code, this.loading = false, this.error, this.opened, this.opens = 0});

  /// The typed code once it is a complete, valid code.
  final String? code;
  final bool loading;
  final CodeEntryError? error;

  /// The code to open; [opens] counts each time, so the view navigates once per open.
  final String? opened;
  final int opens;

  bool get limited => error == CodeEntryError.limited;

  CodeEntryState copyWith({
    String? Function()? code,
    bool? loading,
    CodeEntryError? Function()? error,
    String? opened,
    int? opens,
  }) => CodeEntryState(
    code: code != null ? code() : this.code,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
    opened: opened ?? this.opened,
    opens: opens ?? this.opens,
  );

  @override
  List<Object?> get props => [code, loading, error, opened, opens];
}
