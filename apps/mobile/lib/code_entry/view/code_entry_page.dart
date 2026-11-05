// G8, the home screen (S7 FR-004, UI design F-G8): a 6-character code field with the unambiguous
// alphabet, upper-cased and paste-friendly. An unknown code shows inline and keeps the code; a
// rate-limited device is told to wait (PRD R10). A valid code opens the invite.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../repositories/invite_repository.dart';
import '../../shell/shell.dart';
import '../../ui/art.dart';
import '../../ui/components.dart';
import '../bloc/code_entry_bloc.dart';
import '../widgets/code_formatter.dart';

const invalidCodeError = 'That code doesn’t match an invite. Check the letters.';
const rateLimitedError = 'Too many attempts from this device. Try again in an hour.';

class CodeEntryPage extends StatelessWidget {
  const CodeEntryPage({super.key, this.initialError});

  /// From an invite link that didn't resolve (`invalid` or `limited`).
  final String? initialError;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => CodeEntryBloc(inviteRepository: context.read<InviteRepository>(), initialError: initialError),
    child: const CodeEntryView(),
  );
}

class CodeEntryView extends StatefulWidget {
  const CodeEntryView({super.key});

  @override
  State<CodeEntryView> createState() => _CodeEntryViewState();
}

class _CodeEntryViewState extends State<CodeEntryView> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CodeEntryBloc>().state;
    return BlocListener<CodeEntryBloc, CodeEntryState>(
      listenWhen: (p, c) => p.opens != c.opens,
      listener: (context, state) => context.push('/i/${state.opened}'),
      child: Scaffold(
        // My plans is a tab now (S7b FR-002); the bar carries the role toggle.
        appBar: const VAppBar(wordmark: true, trailing: RoleToggle()),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s6, VelioSpace.s5, VelioSpace.s8),
              child: ConstrainedBox(
                // Never negative: with the keyboard up the space can be shorter than the padding.
                constraints: BoxConstraints(minHeight: max(0, box.maxHeight - VelioSpace.s6 - VelioSpace.s8)),
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
                          error: switch (state.error) {
                            CodeEntryError.invalid => invalidCodeError,
                            CodeEntryError.limited => rateLimitedError,
                            null => null,
                          },
                          enabled: !state.limited,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.go,
                          inputFormatters: [CodeFormatter()],
                          onChanged: (text) => context.read<CodeEntryBloc>().add(CodeEntryChanged(text)),
                          onSubmitted: (_) => context.read<CodeEntryBloc>().add(const CodeEntrySubmitted()),
                        ),
                        const SizedBox(height: VelioSpace.s5),
                        VButton(
                          state.loading ? 'Opening…' : (state.limited ? 'Try again in an hour' : 'Open invite'),
                          block: true,
                          loading: state.loading,
                          onPressed: state.code != null && !state.limited
                              ? () => context.read<CodeEntryBloc>().add(const CodeEntrySubmitted())
                              : null,
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
      ),
    );
  }
}
