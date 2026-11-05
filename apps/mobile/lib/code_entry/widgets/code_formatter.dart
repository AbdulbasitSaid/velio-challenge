import 'package:flutter/services.dart';

import '../../domain/format.dart';

/// Upper-cases and drops characters a code can't have, so a pasted "k7pq-2n" becomes "K7PQ2N".
class CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = codeInput(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
