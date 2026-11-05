// X1 sign in (S7 FR-017, PRD Q14): name and the phone or email used before, so My plans works on a
// new phone. Only a masked contact is kept on the device (SEC-002).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../../connectivity/cubit/connectivity_cubit.dart';
import '../../repositories/session_repository.dart';
import '../../ui/components.dart';
import '../bloc/sign_in_bloc.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, this.next});

  /// Where to go after signing in; only app paths are accepted.
  final String? next;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SignInBloc(sessionRepository: context.read<SessionRepository>(), next: next),
    child: const SignInView(),
  );
}

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _name = TextEditingController();
  final _contact = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() => context.read<SignInBloc>().add(SignInSubmitted(name: _name.text, contact: _contact.text));

  @override
  Widget build(BuildContext context) {
    final online = context.select((ConnectivityCubit c) => c.state);
    final state = context.watch<SignInBloc>().state;
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (p, c) => p.destination != c.destination && c.destination != null,
      listener: (context, state) => context.go(state.destination!),
      child: Scaffold(
        appBar: VAppBar(
          leading: VIconButton(
            'back',
            label: 'Back',
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: 'Sign in',
        ),
        body: SafeArea(
          top: false,
          child: AutofillGroup(
            child: ScreenBody(
              children: [
                Semantics(header: true, child: Text('Continue to Velio', style: VelioText.title)),
                Text(
                  'Your name and a phone number or email. No password.',
                  style: VelioText.body.copyWith(color: VelioColors.muted),
                ),
                if (state.error != null) VBanner(tone: BannerTone.error, title: state.error!),
                VTextField(
                  label: 'Your name',
                  controller: _name,
                  placeholder: 'First and last name',
                  help: 'Others see your first name and last initial.',
                  error: state.nameError,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                ),
                VTextField(
                  label: 'Phone or email',
                  controller: _contact,
                  keyboardType: TextInputType.emailAddress,
                  placeholder: '+254 7… or you@example.com',
                  help: 'Use the same one on every device to see your plans. We don’t message you.',
                  error: state.contactError,
                  autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.email],
                  onSubmitted: (_) => _submit(),
                ),
                VButton(
                  state.busy
                      ? 'Continuing…'
                      : online
                      ? 'Continue'
                      : 'Reconnect to continue',
                  block: true,
                  loading: state.busy,
                  onPressed: online ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
