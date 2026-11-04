// G8, the home screen (S7 FR-004, UI design F-G8): a 6-character code field with the unambiguous
// alphabet, upper-cased and paste-friendly. An unknown code shows inline and keeps the code; a
// rate-limited device is told to wait (PRD R10). A valid code opens the invite.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/providers.dart';
import '../ui/art.dart';
import '../ui/components.dart';

const invalidCodeError = 'That code doesn’t match an invite. Check the letters.';
const rateLimitedError = 'Too many attempts from this device. Try again in an hour.';

class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key, this.initialError});

  /// From an invite link that didn't resolve (`invalid` or `limited`).
  final String? initialError;

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryState();
}

class _CodeEntryState extends ConsumerState<CodeEntryScreen> {
  final _field = TextEditingController();
  bool _loading = false;
  bool _limited = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _limited = widget.initialError == 'limited';
    _error = switch (widget.initialError) {
      'invalid' => invalidCodeError,
      'limited' => rateLimitedError,
      _ => null,
    };
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final code = normaliseCode(_field.text);
    if (code == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Checked here so an unknown code stays on this screen with the code kept (PRD Edge cases).
      final view = await ref.read(apiProvider).invite(code);
      await ref.read(cacheProvider).saveInvite(view, ref.read(clockProvider)());
      if (mounted) context.push('/i/$code');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.network) {
        // Offline: the invite screen shows the saved copy if it's this code, or says so.
        context.push('/i/$code');
      } else {
        setState(() {
          _limited = e.code == 'rate_limited';
          _error = _limited ? rateLimitedError : invalidCodeError;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = normaliseCode(_field.text) != null;
    return Scaffold(
      appBar: VAppBar(
        wordmark: true,
        trailing: VButton(
          'My plans',
          variant: ButtonVariant.quiet,
          small: true,
          onPressed: () => context.push('/me/plans'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s6, VelioSpace.s5, VelioSpace.s8),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - VelioSpace.s6 - VelioSpace.s8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(header: true, child: Text('Got an invite code?', style: VelioText.title)),
                      const SizedBox(height: VelioSpace.s5),
                      Text(
                        'Type the 6 characters from the message your friend sent. Letters and numbers only, no O or 0 to mix up.',
                        style: VelioText.body.copyWith(color: VelioColors.muted),
                      ),
                      const SizedBox(height: VelioSpace.s5),
                      VTextField(
                        label: 'Invite code',
                        controller: _field,
                        code: true,
                        placeholder: 'K7PQ2N',
                        error: _error,
                        enabled: !_limited,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.go,
                        inputFormatters: [_CodeFormatter()],
                        onChanged: (_) => setState(() => _error = _limited ? _error : null),
                        onSubmitted: (_) => _open(),
                      ),
                      const SizedBox(height: VelioSpace.s5),
                      VButton(
                        _loading ? 'Opening…' : (_limited ? 'Try again in an hour' : 'Open invite'),
                        block: true,
                        loading: _loading,
                        onPressed: complete && !_limited ? _open : null,
                      ),
                      const SizedBox(height: VelioSpace.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 14),
                        decoration: BoxDecoration(
                          color: VelioColors.surface,
                          borderRadius: BorderRadius.circular(VelioRadius.card),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VIcon('info'),
                            const SizedBox(width: VelioSpace.s3),
                            Expanded(
                              child: Text(
                                'Got a link instead? Tap it and it opens straight in the app.',
                                style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Upper-cases and drops characters a code can't have, so a pasted "k7pq-2n" becomes "K7PQ2N".
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = codeInput(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
